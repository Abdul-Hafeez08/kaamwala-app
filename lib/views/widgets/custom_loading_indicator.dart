import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final String? message;

  const CustomLoadingIndicator({
    super.key,
    this.size = 60.0,
    this.color,
    this.message,
  });

  @override
  State<CustomLoadingIndicator> createState() => _CustomLoadingIndicatorState();
}

class _CustomLoadingIndicatorState extends State<CustomLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.color ?? Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Inner pulsing dot
                    Transform.scale(
                      scale:
                          0.8 +
                          (math.sin(_controller.value * 2 * math.pi) * 0.2),
                      child: Container(
                        width: widget.size * 0.4,
                        height: widget.size * 0.4,
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: widget.size * 0.2,
                            height: widget.size * 0.2,
                            decoration: BoxDecoration(
                              color: themeColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: themeColor.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Outer spinning arcs
                    Transform.rotate(
                      angle: _controller.value * 2 * math.pi,
                      child: CustomPaint(
                        painter: _ArcPainter(color: themeColor),
                        size: Size(widget.size, widget.size),
                      ),
                    ),
                    Transform.rotate(
                      angle: -_controller.value * 2 * math.pi,
                      child: CustomPaint(
                        painter: _ArcPainter(
                          color: themeColor.withValues(alpha: 0.5),
                          isInner: true,
                        ),
                        size: Size(widget.size * 0.7, widget.size * 0.7),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity:
                      0.5 +
                      (math.sin(_controller.value * 2 * math.pi) * 0.5).abs(),
                  child: Text(
                    widget.message!,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  final bool isInner;

  _ArcPainter({required this.color, this.isInner = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = isInner ? 2.0 : 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw two opposite arcs
    canvas.drawArc(rect, 0, math.pi / 2, false, paint);
    canvas.drawArc(rect, math.pi, math.pi / 2, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isInner != isInner;
  }
}
