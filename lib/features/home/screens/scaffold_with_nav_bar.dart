import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/neumorphic_bottom_nav.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NeumorphicBottomNav(navigationShell: navigationShell),
    );
  }
}
