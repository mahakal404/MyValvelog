import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/settings_provider.dart';
import 'dashboard_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to the next screen after 2.5 seconds
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => settings.isFirstLaunch
                ? const OnboardingScreen()
                : const DashboardScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A192F), // Deep navy blue
              Color(0xFF004D99), // Brighter tech blue
            ],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.9 + (value * 0.1), // Gentle scale-in effect
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withValues(alpha: 0.6),
                            blurRadius: 60,
                            spreadRadius: 15,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30.0),
                        child: Image.asset(
                          'assets/icon/hv.jpg',
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'MYValve Log',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30.0),
                child: Text(
                  'Crafted by RNEXT',
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
