// lib/screens/splash_screen.dart

import 'package:chefbot_app/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chefbot_app/screens/welcome_screen.dart'; 
import 'package:chefbot_app/screens/XXXhome_screen.dart'; // The main app screen
import 'package:chefbot_app/screens/main_layout_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  // Listens to the auth state and navigates the user accordingly
  Future<void> _redirect() async {
    // Wait for the widgets to be built before navigating
    await Future.delayed(Duration.zero); 

    // Listen to the auth state stream
    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session == null) {
        // User is not logged in, show the initial Welcome screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      } else {
        // User is logged in, redirect to the main app screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show a simple loading indicator while checking auth state
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}