import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/florence_loader.dart';

class FlorenceToast {
  static OverlayEntry? _currentOverlay;

  static void show(BuildContext context, String message) {
    if (!context.mounted) return;

    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) return;
    
    // Remove previous toast if still visible
    if (_currentOverlay != null && _currentOverlay!.mounted) {
      _currentOverlay!.remove();
    }
    _currentOverlay = null;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 55.0,
        left: 0,
        right: 0,
        child: Align(
          alignment: Alignment.center,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, -20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: IgnorePointer(
                child: Container(
                  height: 120, // Give it some height to show the logo
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppColors.ivory,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Subdued watermark
                      Positioned(
                        bottom: -10, // Anchor to bottom
                        child: Opacity(
                          opacity: 0.08, // Very faint
                          child: IgnorePointer(
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: CustomPaint(
                                painter: FlorenceDomePainter(
                                  progress: 1.0, // Fully drawn
                                  color: AppColors.charcoal, // Neutral base for watermark
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Text content on top
                      Text(
                        message,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                          height: 1.5,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    _currentOverlay = overlayEntry;
    overlayState.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      if (_currentOverlay == overlayEntry && overlayEntry.mounted) {
        overlayEntry.remove();
        _currentOverlay = null;
      }
    });
  }
}
