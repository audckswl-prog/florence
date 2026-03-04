import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'neumorphic_container.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData? icon;
  final Widget? illustration;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    this.icon,
    this.illustration,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  }) : assert(
         icon != null || illustration != null,
         'Either icon or illustration must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon or Illustration container
            NeumorphicContainer(
              padding: const EdgeInsets.all(24),
              shape: BoxShape.circle,
              depth: -4.0, // Inset effect for the icon container
              child:
                  illustration ?? Icon(icon, size: 48, color: AppColors.grey),
            ),
            const SizedBox(height: 32),
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.burgundy,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              // Subtitle
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              // Action Button
              GestureDetector(
                onTap: onAction,
                child: NeumorphicContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  borderRadius: 30,
                  depth: 4.0,
                  color: AppColors.ivory,
                  child: Text(
                    actionLabel!,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.burgundy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
