import 'package:flutter/material.dart';
import 'package:refound/theme/apptheme.dart';
import 'package:refound/widgets/header.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── Hero ──
          HeroHeader(
            height: 230,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Container(
                     width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15),
                              blurRadius: 12, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(
                          'lib/assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                const SizedBox(height: 12),
                const Text('ReFound',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    )),
                const SizedBox(height: 6),
                Text(
                  'Reuniting people with their belongings',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.65), fontSize: 13),
                ),
              ],
            ),
          ),

          // ── Body ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                children: [
                  // Feature grid
                  Row(children: [
                    _FeatureCard(icon: Icons.search_rounded,
                        label: 'Search Items', color: const Color(0xFFE0F2FE)),
                    const SizedBox(width: 12),
                    _FeatureCard(icon: Icons.map_outlined,
                        label: 'Map View', color: const Color(0xFFD1FAE5)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    _FeatureCard(icon: Icons.notifications_outlined,
                        label: 'Quick Reporting', color: const Color(0xFFFEF3C7)),
                    const SizedBox(width: 12),
                    _FeatureCard(icon: Icons.verified_user_outlined,
                        label: 'Secure & Private', color: const Color(0xFFEDE9FE)),
                  ]),

                  const Spacer(),

                  // CTA
                  const Text('Get Started',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      )),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureCard(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05),
                blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}