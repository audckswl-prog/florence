import 'package:flutter/material.dart';

class WritingText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Duration duration;
  final TextAlign textAlign;

  const WritingText({
    super.key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 1500),
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: text.length),
      duration: duration,
      builder: (context, value, child) {
        return Text(
          text.substring(0, value),
          style: style,
          textAlign: textAlign,
        );
      },
    );
  }
}
