import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
// import 'neumorphic_container.dart';

class NeumorphicBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const NeumorphicBottomNav({super.key, required this.navigationShell});

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1.0)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, 0, Icons.home_rounded, '홈'),
            _buildNavItem(context, 1, Icons.edit_note_rounded, '메모'),
            _buildNavItem(context, 2, Icons.auto_stories_rounded, '책 보관함'),
            _buildNavItem(context, 3, Icons.person_rounded, '마이'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = navigationShell.currentIndex == index;
    final color = isSelected ? AppColors.burgundy : AppColors.grey;

    return InkWell(
      onTap: () => _onTap(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
            // shadows: isSelected
            //     ? [
            //         BoxShadow(
            //           color: AppColors.burgundy.withOpacity(0.3),
            //           blurRadius: 8,
            //           offset: const Offset(2, 2),
            //         ),
            //       ]
            //     : null,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
