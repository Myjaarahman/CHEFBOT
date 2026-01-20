import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:chefbot_app/utils/constants.dart'; // We'll define this file shortly
import 'package:chefbot_app/screens/splash_screen.dart'; 
import 'package:chefbot_app/models/onboarding_data.dart'; 

final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // IMPORTANT: Replace with your actual Supabase URL and Anon Key!
  await Supabase.initialize(
    url: 'https://bciehccxvamebrmutqww.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJjaWVoY2N4dmFtZWJybXV0cXd3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyODkwMTEsImV4cCI6MjA4MDg2NTAxMX0.96qF3aRqxpb2L0-8aKhea_LFThm5yM7tOMHDI8YaUQg',
  );

  runApp(
    // Wrap the app with the Provider
    ChangeNotifierProvider(
      create: (context) => OnboardingData(),
      child: const ChefBotApp(),
    ),
  );
}

class ChefBotApp extends StatelessWidget {
  const ChefBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChefBot',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFFF5722)), // Use your main orange color
        useMaterial3: true,
      ),
      // We start with the SplashScreen to check the auth state
      home: const SplashScreen(),
    );
  }
}