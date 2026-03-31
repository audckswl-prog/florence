import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/florence_loader.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.ivory,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Firenze',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                fontFamily: 'Serif',
                color: AppColors.burgundy,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(height: 48),
            FlorenceLoader(width: 60, height: 60),
          ],
        ),
      ),
    );
  }
}
