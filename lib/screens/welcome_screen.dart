// lib/screens/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:chefbot_app/screens/login_screen.dart';
import 'package:chefbot_app/screens/signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image (Full screen)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/chefbot_bg.jpeg'), 
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          
          // 2. Dark Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),
          
          // 3. Main Content
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 80.0),
                  child: Column(
                    children: [
                      // --- UPDATED: IMAGE LOGO INSTEAD OF ICON ---
                      Image.asset(
                        'assets/images/chefbot_logo.png', // Ensure this filename matches your asset
                        height: 100, // Adjusted size for a logo
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 10), // Space between logo and text
                      const Text(
                        'CHEFBOT',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'AI-BASED SMART RECIPE PLANNER',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFFF5722),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(), 
                
                const Text(
                  'Start Cooking',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Let\'s join our community to cook better food!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 25),

                // Button 1: Start Cooking
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Start Cooking', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 15),

                // Button 2: Get Started
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SignUpScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Get Started', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}