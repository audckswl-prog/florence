import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class NeumorphicContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double
  depth; // Positive for convex/elevated, Negative for concave/inset (future use)
  final Color? color;
  final BoxShape shape;
  final Border? border;

  const NeumorphicContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 20.0,
    this.depth = 4.0,
    this.color,
    this.shape = BoxShape.rectangle,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? AppColors.ivory;

    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(borderRadius),
        shape: shape,
        border: border,
        boxShadow: depth != 0
            ? [
                // Top-left light source (Highlight)
                BoxShadow(
                  color: AppColors.shadowLight,
                  offset: Offset(-depth, -depth),
                  blurRadius: (depth * 2).abs(),
                  spreadRadius: 1, // Subtle spread
                ),
                // Bottom-right shadow (Shadow)
                BoxShadow(
                  color: AppColors.shadowDark,
                  offset: Offset(depth, depth),
                  blurRadius: (depth * 2).abs(),
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
