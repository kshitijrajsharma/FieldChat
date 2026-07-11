import 'package:flutter/material.dart';
import 'package:hulaki/design/app_colors.dart';
import 'package:hulaki/design/app_typography.dart';
import 'package:hulaki/design/brand/hulaki_logo.dart';

/// Brand splash: the reversed lockup on ink. Shown while the local store
/// opens and the session is restored.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.ink,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HulakiWordmark(height: 34, color: AppColors.white, fontSize: 34),
            SizedBox(height: 10),
            Text(
              'Collect field data while chatting',
              style: TextStyle(
                fontFamily: AppFonts.accent,
                fontSize: 20,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
