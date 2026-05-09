import 'package:flutter/material.dart';
import 'package:refound/theme/apptheme.dart';


class HeroHeader extends StatelessWidget {
  final Widget child;
  final double height;

  const HeroHeader({super.key, required this.child, this.height = 180});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.navyMid, AppColors.navyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30, right: -30,
            child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 10, left: -20,
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ),
          SafeArea(child: Center(child: child)),
        ],
      ),
    );
  }
}