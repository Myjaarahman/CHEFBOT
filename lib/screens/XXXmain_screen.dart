// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:chefbot_app/screens/XXXhome_screen.dart';
import 'package:chefbot_app/screens/scanner_screen.dart'; 
// Placeholder screens for future development
import 'package:chefbot_app/screens/infographic_screen.dart';
import 'package:chefbot_app/screens/starred_screen.dart';
import 'package:chefbot_app/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // Starts on 'Home'

  // Define the list of screens corresponding to the tabs
  final List<Widget> _screens = [
    const HomeScreen(),
    const InfographicScreen(), // Placeholder
    const ScannerScreen(),    // Scanner UI we just worked on
    const SavedRecipesScreen(), // Placeholder
    const ProfileScreen(),      // Placeholder
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The currently selected screen is shown here
      body: _screens[_currentIndex],
      
      // The Bottom Navigation Bar (Matching your mockup styling)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home), 
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu), // Using menu icon for 'Infographic' as a placeholder
            label: 'Infographic',
          ),
          // Custom 'Scan' button is usually styled differently
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4.0), // Lift the icon slightly
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFFF5722), // Your main orange color
                child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 28), // Scanner icon
              ),
            ),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star), 
            label: 'Starred',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), 
            label: 'Profile',
          ),
        ],
        
        // Styling to match your brand and mockup
        selectedItemColor: const Color(0xFFFF5722),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed, // Essential for showing all labels
        showUnselectedLabels: true, // Show all labels clearly
      ),
    );
  }
}

// Placeholder Screens (minimal implementation)

class InfographicScreen extends StatelessWidget {
  const InfographicScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Infographic Screen (Placeholder)')));
  }
}

class SavedRecipesScreen extends StatelessWidget {
  const SavedRecipesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Starred/Saved Recipes Screen (Placeholder)')));
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('User Profile Screen (Placeholder)')));
  }
}