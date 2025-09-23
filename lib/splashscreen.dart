import 'dart:async';

import 'package:esquare/screens/login_screens.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    _checkLoginStatus();
  }

  /// **NEW: Checks SharedPreferences for a saved user session.**
  Future<void> _checkLoginStatus() async {
    // Wait for a couple of seconds for the animation to play.
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return; // Ensure the widget is still in the tree.

    final prefs = await SharedPreferences.getInstance();


    final bool isLoggedIn = prefs.containsKey('user');

    if (isLoggedIn) {
      // If logged in, go directly to the dashboard.
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      // If not logged in, go to the login screen.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Image.asset('assets/images/ddLight.png'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
