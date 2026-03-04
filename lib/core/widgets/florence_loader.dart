import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants/app_colors.dart';

class FlorenceLoader extends StatefulWidget {
  final double width;
  final double height;
  final Color? color;

  const FlorenceLoader({
    super.key,
    this.width = 60.0,
    this.height = 60.0, // Increased default height for better proportion
    this.color,
  });

  @override
  State<FlorenceLoader> createState() => _FlorenceLoaderState();
}

class _FlorenceLoaderState extends State<FlorenceLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: FlorenceDomePainter(
              progress: _controller.value,
              color: widget.color ?? AppColors.burgundy,
            ),
          );
        },
      ),
    );
  }
}

/// A wrapper that keeps the loader visible until the current animation cycle finishes,
/// even after [isLoading] becomes false.
class FlorenceLoadingOverlay extends StatefulWidget {
  final bool isLoading;
  final Widget child;
  final Color backgroundColor;

  const FlorenceLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.backgroundColor = AppColors.ivory, // Default app background
  });

  @override
  State<FlorenceLoadingOverlay> createState() => _FlorenceLoadingOverlayState();
}

class _FlorenceLoadingOverlayState extends State<FlorenceLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showLoader = false;

  @override
  void initState() {
    super.initState();
    _showLoader = widget.isLoading;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Cycle finished. If not loading, hide.
        if (!widget.isLoading) {
          // Only update state if mounted
          if (mounted) {
            setState(() {
              _showLoader = false;
            });
          }
        }
      }
    });

    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(FlorenceLoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        // Start Loading
        if (mounted) {
          setState(() {
            _showLoader = true;
          });
        }
        _controller.repeat();
      } else {
        // Stop Loading -> Finish cycle
        // 'forward' enables the controller to proceed to 1.0 and stop there.
        // This gracefully exits the 'repeat' loop.
        final current = _controller.value;
        _controller.forward(from: current);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showLoader)
          Positioned.fill(
            child: Container(
              color: widget.backgroundColor,
              child: Center(
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => CustomPaint(
                      painter: FlorenceDomePainter(
                        progress: _controller.value,
                        color: AppColors.burgundy,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class FlorenceDomePainter extends CustomPainter {
  final double progress;
  final Color color;

  FlorenceDomePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w / 2;

    // Define the standardized path for the Duomo
    // Proportions roughly based on Brunelleschi's Dome
    final path = Path();

    // Base width factors
    final double baseWidth = w * 0.8;
    final double startX = (w - baseWidth) / 2;
    final double endX = w - startX;

    // Heights
    final double baseY = h * 0.9;
    final double drumY = h * 0.65; // The octagonal drum top
    final double lanternY = h * 0.25; // Top of the dome curve (base of lantern)

    // 1. The Drum (Base walls)
    path.moveTo(startX, baseY);
    path.lineTo(startX, drumY);

    // 2. The Dome Curves (Gothic Arch - Pointed)
    // Left curve
    path.quadraticBezierTo(
      startX,
      lanternY * 1.5, // Control point
      centerX,
      lanternY, // End point (Apex)
    );

    // Right curve
    path.quadraticBezierTo(
      endX,
      lanternY * 1.5, // Control point matching left
      endX,
      drumY, // End point
    );

    path.lineTo(endX, baseY);
    path.close();

    // Ribs (Internal lines)
    final ribPath = Path();
    // Left rib
    ribPath.moveTo(
      startX + (baseWidth * 0.25),
      drumY * 1.02,
    ); // Slightly lower than drum line
    ribPath.quadraticBezierTo(
      startX + (baseWidth * 0.28),
      lanternY * 1.5,
      centerX,
      lanternY,
    );
    // Right rib
    ribPath.moveTo(endX - (baseWidth * 0.25), drumY * 1.02);
    ribPath.quadraticBezierTo(
      endX - (baseWidth * 0.28),
      lanternY * 1.5,
      centerX,
      lanternY,
    );

    // Lantern (Cupola)
    final lanternPath = Path();
    final double lanternW = baseWidth * 0.15;
    final double lanternH = (drumY - lanternY) * 0.4;
    final double lanternTop = lanternY - lanternH;

    lanternPath.moveTo(centerX - lanternW / 2, lanternY);
    lanternPath.lineTo(centerX - lanternW / 2, lanternTop);
    lanternPath.lineTo(centerX + lanternW / 2, lanternTop);
    lanternPath.lineTo(centerX + lanternW / 2, lanternY);

    // Cross
    final crossPath = Path();
    final double crossH = lanternH * 0.6;
    crossPath.moveTo(centerX, lanternTop);
    crossPath.lineTo(centerX, lanternTop - crossH);
    crossPath.moveTo(centerX - lanternW * 0.4, lanternTop - crossH * 0.6);
    crossPath.lineTo(centerX + lanternW * 0.4, lanternTop - crossH * 0.6);

    // --- Animation Logic ---

    // Phase 1: Drawing Outlines (0.0 - 0.5)
    final double drawProgress = (progress / 0.5).clamp(0.0, 1.0);

    if (drawProgress > 0) {
      final outlinePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      _drawAnimatedPath(canvas, path, drawProgress, outlinePaint);
      _drawAnimatedPath(canvas, ribPath, drawProgress, outlinePaint);
      _drawAnimatedPath(canvas, lanternPath, drawProgress, outlinePaint);
      _drawAnimatedPath(canvas, crossPath, drawProgress, outlinePaint);
    }

    // Phase 2: Filling (0.5 - 0.8)
    final double fillProgress = ((progress - 0.5) / 0.3).clamp(0.0, 1.0);

    if (fillProgress > 0) {
      final fillPaint = Paint()
        ..color = color.withOpacity(fillProgress)
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(lanternPath, fillPaint);

      // When filled, we might want to draw ribs in white/background color to make them visible
      if (fillProgress > 0.5) {
        final ribOverlayPaint = Paint()
          ..color = Colors.white
              .withOpacity(fillProgress * 0.7) // Semi-transparent white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        canvas.drawPath(ribPath, ribOverlayPaint);
      }
    }
  }

  void _drawAnimatedPath(
    Canvas canvas,
    Path path,
    double progress,
    Paint paint,
  ) {
    if (progress <= 0) return;

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      final extractPath = metric.extractPath(0.0, metric.length * progress);
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant FlorenceDomePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
