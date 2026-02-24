import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'neumorphic_container.dart';

class NeumorphicButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const NeumorphicButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 20.0,
    this.color,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double depth = _isPressed ? 0.0 : 4.0; // Pressed state flattens the shadow
    
    // Slight movement when pressed to simulate physical button
    final double offset = _isPressed ? 2.0 : 0.0;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Transform.translate(
        offset: Offset(offset, offset),
        child: NeumorphicContainer(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          borderRadius: widget.borderRadius,
          color: widget.color ?? (widget.onPressed == null ? AppColors.ivoryDark : AppColors.ivory),
          depth: depth,
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
