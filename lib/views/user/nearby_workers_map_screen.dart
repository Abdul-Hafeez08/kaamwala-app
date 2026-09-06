import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import '../../models/service_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/location_service.dart';
import '../widgets/custom_loading_indicator.dart';
import 'booking_screen.dart';
import 'general_post_screen.dart';
import 'worker_detail_screen.dart';

class NearbyWorkersMapScreen extends ConsumerStatefulWidget {
  const NearbyWorkersMapScreen({super.key});

  @override
  ConsumerState<NearbyWorkersMapScreen> createState() =>
      _NearbyWorkersMapScreenState();
}

class _NearbyWorkersMapScreenState
    extends ConsumerState<NearbyWorkersMapScreen> with TickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  final ScrollController _scrollController = ScrollController();

  Position? _currentPosition;
  bool _isLocating = true;
  bool _locationPermissionNeeded = false;
  double _selectedRadius = 50.0;
  String _selectedCategory = 'All Services';
  WorkerModel? _selectedWorker;
  List<String> _serviceOptions = ['All Services'];

  static const ll.LatLng _defaultCenter = ll.LatLng(31.5204, 74.3587); // Lahore Center

  @override
  void initState() {
    super.initState();
    _loadServiceOptions();
    _fetchUserLocation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadServiceOptions() async {
    try {
      final services = await ref.read(firestoreServiceProvider).getServices();
      final names = services
          .map((service) => service.name)
          .where((name) => name.trim().isNotEmpty)
          .toSet()
          .toList();
      names.sort();
      if (mounted) {
        setState(() {
          _serviceOptions = ['All Services', ...names];
          if (!_serviceOptions.contains(_selectedCategory)) {
            _selectedCategory = 'All Services';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _serviceOptions = ['All Services', ...serviceCategoryNames];
          if (!_serviceOptions.contains(_selectedCategory)) {
            _selectedCategory = 'All Services';
          }
        });
      }
    }
  }

  Future<void> _fetchUserLocation() async {
    if (!mounted) return;
    setState(() {
      _isLocating = true;
    });

    try {
      final pos = await _locationService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _locationPermissionNeeded = false;
          _isLocating = false;
        });
        _animatedMove(ll.LatLng(pos.latitude, pos.longitude), 13.5);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Location fetch error (using default location): $e');
      }
      if (mounted) {
        setState(() {
          _locationPermissionNeeded = true;
          _currentPosition = Position(
            latitude: _defaultCenter.latitude,
            longitude: _defaultCenter.longitude,
            timestamp: DateTime.now(),
            accuracy: 100,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
          _isLocating = false;
        });
      }
    }
  }

  void _animatedMove(ll.LatLng destLocation, double destZoom) {
    try {
      _mapController.move(destLocation, destZoom);
    } catch (_) {}
  }

  void _fitAllWorkers(List<WorkerModel> workers) {
    final userLat = _currentPosition?.latitude ?? _defaultCenter.latitude;
    final userLng = _currentPosition?.longitude ?? _defaultCenter.longitude;

    if (workers.isEmpty) {
      _animatedMove(ll.LatLng(userLat, userLng), 13.5);
      return;
    }

    double minLat = userLat;
    double maxLat = userLat;
    double minLng = userLng;
    double maxLng = userLng;

    for (final w in workers) {
      minLat = min(minLat, w.latitude);
      maxLat = max(maxLat, w.latitude);
      minLng = min(minLng, w.longitude);
      maxLng = max(maxLng, w.longitude);
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    final maxDiff = max((maxLat - minLat).abs(), (maxLng - minLng).abs());

    double targetZoom = 13.0;
    if (maxDiff > 1.0) {
      targetZoom = 8.0;
    } else if (maxDiff > 0.5) {
      targetZoom = 9.5;
    } else if (maxDiff > 0.2) {
      targetZoom = 11.0;
    } else if (maxDiff > 0.08) {
      targetZoom = 12.5;
    } else {
      targetZoom = 13.5;
    }

    _animatedMove(ll.LatLng(centerLat, centerLng), targetZoom);
  }

  Future<void> _refreshAll() async {
    await _fetchUserLocation();
    ref.invalidate(nearbyAvailableWorkersStreamProvider);
  }

  /// STRICT, UNIFIED worker filter:
  /// 1. Must have availability == true
  /// 2. Must EXACTLY match selected category (if not "All Services")
  /// 3. Must have real, non-zero coordinates
  /// 4. Must be within the selected radius
  List<WorkerModel> _filterWorkers(List<WorkerModel> rawWorkers) {
    final userLat = _currentPosition?.latitude ?? _defaultCenter.latitude;
    final userLng = _currentPosition?.longitude ?? _defaultCenter.longitude;
    final selectedCat = _selectedCategory.trim().toLowerCase();

    final List<WorkerModel> filtered = [];

    for (final worker in rawWorkers) {
      // 1. Availability check: Worker must be available / open to work
      if (!worker.availability) {
        continue;
      }

      // 2. Strict category check (Case-insensitive exact match)
      if (selectedCat != 'all services') {
        final workerService = worker.serviceType.trim().toLowerCase();
        if (workerService.isEmpty || workerService != selectedCat) {
          continue;
        }
      }

      // 3. Coordinate validation (must have real non-zero GPS coordinates)
      final workerLat = worker.latitude;
      final workerLng = worker.longitude;

      if (workerLat == 0.0 && workerLng == 0.0) {
        continue;
      }

      // 4. Distance calculation in km
      final distanceKm = _locationService.calculateDistance(
        userLat,
        userLng,
        workerLat,
        workerLng,
      );

      if (distanceKm <= _selectedRadius) {
        filtered.add(worker);
      }
    }

    // Sort by distance (nearest first)
    filtered.sort((a, b) {
      final distA = _locationService.calculateDistance(
        userLat,
        userLng,
        a.latitude,
        a.longitude,
      );
      final distB = _locationService.calculateDistance(
        userLat,
        userLng,
        b.latitude,
        b.longitude,
      );
      return distA.compareTo(distB);
    });

    return filtered;
  }

  IconData _getServiceIcon(String serviceType) {
    final s = serviceType.toLowerCase();
    if (s.contains('electr')) return Icons.bolt_rounded;
    if (s.contains('plumb')) return Icons.plumbing_rounded;
    if (s.contains('maid') || s.contains('clean')) return Icons.cleaning_services_rounded;
    if (s.contains('ac') || s.contains('cool')) return Icons.ac_unit_rounded;
    if (s.contains('carpent')) return Icons.handyman_rounded;
    if (s.contains('paint')) return Icons.format_paint_rounded;
    if (s.contains('mechan')) return Icons.build_rounded;
    return Icons.work_rounded;
  }

  List<Marker> _buildMapMarkers(List<WorkerModel> workers, bool isDark) {
    final List<Marker> markers = [];
    final userLat = _currentPosition?.latitude ?? _defaultCenter.latitude;
    final userLng = _currentPosition?.longitude ?? _defaultCenter.longitude;

    // 1. User Location Pin (Blue Azure Beacon)
    markers.add(
      Marker(
        point: ll.LatLng(userLat, userLng),
        width: 80,
        height: 60,
        child: Column(
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
              width: 18,
              height: 18,
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
        ),
      ),
    );

    // 2. Dynamic Worker Markers (Strictly from the filtered workers dataset)
    for (final worker in workers) {
      final isSelected = _selectedWorker?.workerId == worker.workerId;
      final serviceIcon = _getServiceIcon(worker.serviceType);

      markers.add(
        Marker(
          point: ll.LatLng(worker.latitude, worker.longitude),
          width: 130,
          height: 72,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedWorker = worker;
              });
              _animatedMove(ll.LatLng(worker.latitude, worker.longitude), 14.5);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Worker Name + Category Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF9800)
                          : (isDark ? Colors.white24 : Colors.black12),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(serviceIcon, size: 11, color: const Color(0xFFFF9800)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          worker.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: isSelected
                                ? const Color(0xFFFF9800)
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                // Worker Avatar / Icon Pin
                Container(
                  width: isSelected ? 36 : 30,
                  height: isSelected ? 36 : 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    serviceIcon,
                    color: Colors.white,
                    size: isSelected ? 18 : 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workersAsync = ref.watch(nearbyAvailableWorkersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nearby Workers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _isLocating ? null : _refreshAll,
            icon: _isLocating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh location and workers',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: workersAsync.when(
        loading: () => const Center(child: CustomLoadingIndicator()),
        error: (err, stack) => _buildErrorState(err.toString(), isDark),
        data: (allWorkers) {
          // ONE SINGLE SOURCE OF TRUTH:
          final nearbyWorkers = _filterWorkers(allWorkers);
          final markers = _buildMapMarkers(nearbyWorkers, isDark);

          final categoryTitle = _selectedCategory == 'All Services'
              ? 'Worker'
              : _selectedCategory;
          final plural = nearbyWorkers.length == 1 ? '' : 's';

          return SafeArea(
            child: Column(
              children: [
                // 1. Filter Bar (Category Dropdown & Radius Dropdown)
                _buildFilterBar(isDark),

                // Location Permission notice if permission was denied
                if (_locationPermissionNeeded)
                  _buildLocationPermissionNotice(isDark),

                // 2. Real Interactive OpenStreetMap Canvas
                Expanded(
                  flex: 5,
                  child: _buildMapContainer(markers, nearbyWorkers, isDark),
                ),

                // 3. Worker Count & Live GPS Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        nearbyWorkers.isEmpty
                            ? '0 ${categoryTitle}s Available'
                            : '${nearbyWorkers.length} $categoryTitle$plural Available Nearby',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Colors.green, size: 8),
                            SizedBox(width: 4),
                            Text(
                              'Live GPS Map',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Scrollable Worker Profile Cards List
                Expanded(
                  flex: 5,
                  child: nearbyWorkers.isEmpty
                      ? _buildNoWorkersState(isDark)
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: nearbyWorkers.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final worker = nearbyWorkers[index];
                            final isSelected =
                                _selectedWorker?.workerId == worker.workerId;
                            return _buildWorkerListTile(
                              worker,
                              isSelected,
                              isDark,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    final radiusItems = [10.0, 25.0, 50.0, 100.0];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
          ),
        ),
      ),
      child: Row(
        children: [
          // Service Category Dropdown
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedCategory,
                  dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  items: _serviceOptions
                      .map(
                        (service) => DropdownMenuItem(
                          value: service,
                          child: Text(
                            service,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategory = val;
                        _selectedWorker = null;
                      });
                    }
                  },
                  icon: const Icon(Icons.arrow_drop_down_rounded),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Radius Dropdown
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<double>(
                  isExpanded: true,
                  value: _selectedRadius,
                  dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  items: radiusItems
                      .map(
                        (radius) => DropdownMenuItem(
                          value: radius,
                          child: Text(
                            '${radius.toInt()} km',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedRadius = val;
                        _selectedWorker = null;
                      });
                    }
                  },
                  icon: const Icon(Icons.arrow_drop_down_rounded),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPermissionNotice(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_searching_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Using default city center. Grant GPS access for precise location.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: _fetchUserLocation,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Enable GPS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF9800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContainer(
    List<Marker> markers,
    List<WorkerModel> nearbyWorkers,
    bool isDark,
  ) {
    final userLat = _currentPosition?.latitude ?? _defaultCenter.latitude;
    final userLng = _currentPosition?.longitude ?? _defaultCenter.longitude;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFF9800).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: ll.LatLng(userLat, userLng),
                initialZoom: 13.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onTap: (_, _) => setState(() => _selectedWorker = null),
              ),
              children: [
                // 1. Clean, 100% Free OpenStreetMap Standard Tile Layer (Zero API Key, Zero Watermarks)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.kaamwala.app',
                  maxZoom: 19,
                ),

                // 2. Search Radius Circle Overlay
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: ll.LatLng(userLat, userLng),
                      radius: _selectedRadius * 1000, // in meters
                      useRadiusInMeter: true,
                      color: const Color(0xFFFF9800).withValues(alpha: 0.08),
                      borderColor: const Color(0xFFFF9800).withValues(alpha: 0.45),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),

                // 3. User and Worker Marker Layer
                MarkerLayer(
                  markers: markers,
                ),
              ],
            ),
          ),

          // Live count badge on top left of map
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: Color(0xFFFF9800),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${nearbyWorkers.length} Active in ${_selectedRadius.toInt()}km',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Map Control Floating Buttons (Right side)
          Positioned(
            top: 10,
            right: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Re-center on My Location
                _buildMapActionBtn(
                  icon: Icons.my_location_rounded,
                  tooltip: 'My Location',
                  isDark: isDark,
                  onTap: () {
                    _animatedMove(ll.LatLng(userLat, userLng), 14.5);
                  },
                ),
                const SizedBox(height: 6),

                // Fit All Workers in view
                if (nearbyWorkers.isNotEmpty) ...[
                  _buildMapActionBtn(
                    icon: Icons.zoom_out_map_rounded,
                    tooltip: 'Fit All Workers',
                    isDark: isDark,
                    onTap: () {
                      _fitAllWorkers(nearbyWorkers);
                    },
                  ),
                  const SizedBox(height: 6),
                ],

                // Zoom in
                _buildMapActionBtn(
                  icon: Icons.add_rounded,
                  tooltip: 'Zoom In',
                  isDark: isDark,
                  onTap: () {
                    try {
                      _animatedMove(_mapController.camera.center, _mapController.camera.zoom + 1.0);
                    } catch (_) {}
                  },
                ),
                const SizedBox(height: 4),

                // Zoom out
                _buildMapActionBtn(
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom Out',
                  isDark: isDark,
                  onTap: () {
                    try {
                      _animatedMove(_mapController.camera.center, _mapController.camera.zoom - 1.0);
                    } catch (_) {}
                  },
                ),
              ],
            ),
          ),

          // Discreet OSM Attribution bottom-left
          Positioned(
            bottom: 4,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 8.5, color: Colors.black54),
              ),
            ),
          ),

          // Selected Worker Popup Card (Bottom floating overlay on top of map)
          if (_selectedWorker != null)
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: _buildWorkerDetailCard(_selectedWorker!, isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildMapActionBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFFFF9800),
            ),
          ),
        ),
      ),
    );
  }

  /// Full Professional Worker Profile Card in the scrollable list below the map
  Widget _buildWorkerListTile(
    WorkerModel worker,
    bool isSelected,
    bool isDark,
  ) {
    final userLat = _currentPosition?.latitude ?? _defaultCenter.latitude;
    final userLng = _currentPosition?.longitude ?? _defaultCenter.longitude;
    final distanceKm = _locationService.calculateDistance(
      userLat,
      userLng,
      worker.latitude,
      worker.longitude,
    );
    final serviceIcon = _getServiceIcon(worker.serviceType);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedWorker = worker;
        });
        _animatedMove(ll.LatLng(worker.latitude, worker.longitude), 14.5);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF9800)
                : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFFF9800).withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Avatar with green online dot
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFFF9800).withValues(alpha: 0.1),
                      backgroundImage: worker.profileImage.isNotEmpty
                          ? NetworkImage(worker.profileImage)
                          : null,
                      child: worker.profileImage.isEmpty
                          ? Icon(
                              serviceIcon,
                              color: const Color(0xFFFF9800),
                              size: 26,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Name, Category, Rating, Distance
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              worker.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.verified_rounded,
                            color: Colors.blue,
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Service Badge & Rating
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(serviceIcon, size: 12, color: const Color(0xFFFF9800)),
                                const SizedBox(width: 4),
                                Text(
                                  worker.serviceType,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFFF9800),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            worker.rating > 0
                                ? worker.rating.toStringAsFixed(1)
                                : 'New',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Distance & Online Status
                      Row(
                        children: [
                          Icon(
                            Icons.near_me_rounded,
                            size: 13,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${distanceKm.toStringAsFixed(1)} km away',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '🟢 Online • Open to Work',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons: View Profile & Book Now
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkerDetailScreen(worker: worker),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      side: const BorderSide(color: Color(0xFFFF9800), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'View Profile',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF9800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingScreen(worker: worker),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerDetailCard(WorkerModel worker, bool isDark) {
    final userLat = _currentPosition?.latitude ?? _defaultCenter.latitude;
    final userLng = _currentPosition?.longitude ?? _defaultCenter.longitude;
    final distanceKm = _locationService.calculateDistance(
      userLat,
      userLng,
      worker.latitude,
      worker.longitude,
    );
    final serviceIcon = _getServiceIcon(worker.serviceType);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF9800).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFFF9800).withValues(alpha: 0.1),
                backgroundImage: worker.profileImage.isNotEmpty
                    ? NetworkImage(worker.profileImage)
                    : null,
                child: worker.profileImage.isEmpty
                    ? Icon(
                        serviceIcon,
                        color: const Color(0xFFFF9800),
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            worker.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: Colors.blue, size: 14),
                      ],
                    ),
                    Text(
                      '${worker.serviceType} • ${distanceKm.toStringAsFixed(1)} km away • ⭐ ${worker.rating > 0 ? worker.rating.toStringAsFixed(1) : "New"}',
                      style: const TextStyle(
                        color: Color(0xFFFF9800),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedWorker = null),
                icon: const Icon(Icons.close_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkerDetailScreen(worker: worker),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFFFF9800)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'View Profile',
                    style: TextStyle(
                      color: Color(0xFFFF9800),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingScreen(worker: worker),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoWorkersState(bool isDark) {
    final categoryLabel = _selectedCategory == 'All Services'
        ? 'workers'
        : _selectedCategory.toLowerCase();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                size: 36,
                color: Color(0xFFFF9800),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'No $categoryLabel currently available within ${_selectedRadius.toInt()} km',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try expanding your search radius or post a direct job request for workers to apply.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    final next = _selectedRadius == 10.0
                        ? 25.0
                        : _selectedRadius == 25.0
                            ? 50.0
                            : 100.0;
                    setState(() => _selectedRadius = next);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    side: const BorderSide(color: Color(0xFFFF9800)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Expand Radius',
                    style: TextStyle(
                      color: Color(0xFFFF9800),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GeneralPostScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Post Job Request',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'Unable to load nearby workers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Please check your network connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshAll,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
