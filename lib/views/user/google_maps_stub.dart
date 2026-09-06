import 'dart:math';
import 'package:flutter/material.dart';

// Interactive visual map for Web & non-native environments.
// Displays a live coordinate grid, distance radius circles, user location pin,
// and worker pins projected dynamically by GPS coordinates.

class MarkerId {
  final String value;
  const MarkerId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkerId && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}

class BitmapDescriptor {
  final double hue;
  const BitmapDescriptor._({this.hue = 30.0});
  static const BitmapDescriptor defaultMarker = BitmapDescriptor._();
  static const double hueAzure = 210.0;
  static const double hueOrange = 30.0;
  static const double hueGreen = 120.0;

  static BitmapDescriptor defaultMarkerWithHue(double hue) =>
      BitmapDescriptor._(hue: hue);
}

class InfoWindow {
  final String title;
  final String snippet;
  const InfoWindow({this.title = '', this.snippet = ''});
}

class CameraPosition {
  final LatLng target;
  final double zoom;
  const CameraPosition({required this.target, this.zoom = 12});
}

class Marker {
  final MarkerId markerId;
  final LatLng position;
  final BitmapDescriptor? icon;
  final InfoWindow infoWindow;
  final VoidCallback? onTap;

  Marker({
    required this.markerId,
    required this.position,
    this.icon,
    InfoWindow? infoWindow,
    this.onTap,
  }) : infoWindow = infoWindow ?? const InfoWindow();
}

class GoogleMap extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final bool mapToolbarEnabled;
  final Function(LatLng)? onTap;

  const GoogleMap({
    super.key,
    required this.initialCameraPosition,
    this.markers = const {},
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = false,
    this.mapToolbarEnabled = false,
    this.onTap,
  });

  @override
  State<GoogleMap> createState() => _GoogleMapState();
}

class _GoogleMapState extends State<GoogleMap> with SingleTickerProviderStateMixin {
  late double _zoom;
  Offset _panOffset = Offset.zero;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _zoom = widget.initialCameraPosition.zoom;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCameraPosition.target.latitude !=
            widget.initialCameraPosition.target.latitude ||
        oldWidget.initialCameraPosition.target.longitude !=
            widget.initialCameraPosition.target.longitude) {
      _panOffset = Offset.zero;
    }
  }

  void _recenter() {
    setState(() {
      _panOffset = Offset.zero;
      _zoom = widget.initialCameraPosition.zoom;
    });
  }

  void _zoomIn() {
    setState(() {
      _zoom = min(_zoom + 1.0, 18.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoom = max(_zoom - 1.0, 6.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final centerLat = widget.initialCameraPosition.target.latitude;
    final centerLng = widget.initialCameraPosition.target.longitude;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final centerPixel = Offset(width / 2, height / 2) + _panOffset;

        // Degree to pixel scaling factor based on zoom
        // At zoom 13, ~0.01 deg is around 60-80 pixels
        final scaleFactor = pow(2, _zoom - 10) * 45.0;

        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _panOffset += details.delta;
            });
          },
          onTapUp: (details) {
            final tapPos = details.localPosition;
            final dX = (tapPos.dx - centerPixel.dx) / (scaleFactor * cos(centerLat * pi / 180));
            final dY = -(tapPos.dy - centerPixel.dy) / scaleFactor;
            widget.onTap?.call(LatLng(centerLat + dY, centerLng + dX));
          },
          child: Container(
            width: width,
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : const Color(0xFFEBF2F7),
            ),
            child: Stack(
              children: [
                // 1. Live Interactive Grid Canvas
                CustomPaint(
                  size: Size(width, height),
                  painter: _MapCanvasPainter(
                    center: centerPixel,
                    scaleFactor: scaleFactor,
                    isDark: isDark,
                    zoom: _zoom,
                  ),
                ),

                // 2. Pulse wave around user location
                Positioned(
                  left: centerPixel.dx - 40,
                  top: centerPixel.dy - 40,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2196F3).withValues(
                            alpha: max(0.0, 0.35 * (1 - _pulseController.value)),
                          ),
                          border: Border.all(
                            color: const Color(0xFF2196F3).withValues(
                              alpha: max(0.0, 0.8 * (1 - _pulseController.value)),
                            ),
                            width: 1.5,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 3. Render Projected Markers
                ...widget.markers.map((marker) {
                  final isUser = marker.markerId.value == 'current_location';
                  
                  // Compute projected coordinates
                  final latDiff = marker.position.latitude - centerLat;
                  final lngDiff = marker.position.longitude - centerLng;

                  // 1 degree latitude ~ 111km, 1 degree longitude ~ 111km * cos(latitude)
                  final x = centerPixel.dx + (lngDiff * cos(centerLat * pi / 180)) * scaleFactor;
                  final y = centerPixel.dy - (latDiff) * scaleFactor;

                  // Skip if completely out of view
                  if (x < -100 || x > width + 100 || y < -100 || y > height + 100) {
                    return const SizedBox.shrink();
                  }

                  return Positioned(
                    left: x - (isUser ? 24 : 20),
                    top: y - (isUser ? 48 : 42),
                    child: GestureDetector(
                      onTap: marker.onTap,
                      child: _MapPinWidget(
                        marker: marker,
                        isUser: isUser,
                        isDark: isDark,
                      ),
                    ),
                  );
                }),

                // 4. Map Overlay Controls (Zoom +, Zoom -, Re-center)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMapButton(
                        icon: Icons.my_location_rounded,
                        tooltip: 'Re-center Location',
                        onTap: _recenter,
                        isDark: isDark,
                        highlight: _panOffset != Offset.zero,
                      ),
                      const SizedBox(height: 8),
                      _buildMapButton(
                        icon: Icons.add_rounded,
                        tooltip: 'Zoom In',
                        onTap: _zoomIn,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 4),
                      _buildMapButton(
                        icon: Icons.remove_rounded,
                        tooltip: 'Zoom Out',
                        onTap: _zoomOut,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                // 5. Compass / Scale Tag
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black54 : Colors.white70,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    child: Text(
                      'Interactive Map View • Zoom ${(_zoom).toStringAsFixed(1)}x',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required bool isDark,
    bool highlight = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: highlight
            ? const Color(0xFFFF9800)
            : (isDark ? const Color(0xFF2D333B) : Colors.white),
        elevation: 3,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: highlight
                  ? Colors.white
                  : (isDark ? Colors.white : const Color(0xFF333333)),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapPinWidget extends StatelessWidget {
  final Marker marker;
  final bool isUser;
  final bool isDark;

  const _MapPinWidget({
    required this.marker,
    required this.isUser,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              '📍 YOU',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2196F3), width: 4),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
          ),
        ],
      );
    }

    // Worker marker
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (marker.infoWindow.title.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxWidth: 110),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFF9800), width: 1),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Text(
              marker.infoWindow.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFF9800),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        // Arrow pointing down
        ClipPath(
          clipper: _TriangleClipper(),
          child: Container(
            width: 10,
            height: 6,
            color: const Color(0xFFFF9800),
          ),
        ),
      ],
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _MapCanvasPainter extends CustomPainter {
  final Offset center;
  final double scaleFactor;
  final bool isDark;
  final double zoom;

  _MapCanvasPainter({
    required this.center,
    required this.scaleFactor,
    required this.isDark,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF21262D) : const Color(0xFFD8E2EA)
      ..strokeWidth = 1.0;

    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF30363D) : const Color(0xFFC8D7E3)
      ..strokeWidth = 3.0;

    final radiusCirclePaint = Paint()
      ..color = const Color(0xFFFF9800).withValues(alpha: isDark ? 0.15 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // 1. Draw city grid pattern
    const gridSize = 40.0;
    final startX = (center.dx % gridSize) - gridSize;
    final startY = (center.dy % gridSize) - gridSize;

    for (double x = startX; x < size.width + gridSize; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = startY; y < size.height + gridSize; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw major avenue lines passing through center
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      roadPaint,
    );
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      roadPaint,
    );

    // 3. Draw concentric distance radius circles (e.g. 5km, 10km, 25km, 50km)
    final radiiKm = [5.0, 10.0, 25.0, 50.0];
    for (final r in radiiKm) {
      // 1 km in degrees is ~ (1 / 111.0)
      final pixelRadius = (r / 111.0) * scaleFactor;
      if (pixelRadius > 5 && pixelRadius < max(size.width, size.height) * 2) {
        canvas.drawCircle(center, pixelRadius, radiusCirclePaint);

        // Draw distance label
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${r.toInt()} km',
            style: TextStyle(
              color: const Color(0xFFFF9800).withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(center.dx + pixelRadius + 2, center.dy - 10));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.scaleFactor != scaleFactor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.zoom != zoom;
  }
}

