// lib/utils/constants.dart

import 'package:flutter/material.dart';

// 1. Supabase Credentials (Replace placeholders with your actual keys!)
const String supabaseUrl = 'https://bciehccxvamebrmutqww.supabase.co'; 
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJjaWVoY2N4dmFtZWJybXV0cXd3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyODkwMTEsImV4cCI6MjA4MDg2NTAxMX0.96qF3aRqxpb2L0-8aKhea_LFThm5yM7tOMHDI8YaUQg'; 

// 2. Global Navigator Key for Supabase Auth Deep Linking
// This allows the Supabase package to navigate between screens regardless of context.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// --- UI Constants (Optional but Recommended) ---
const Color kPrimaryColor = Color(0xFFFF5722); // ChefBot Orange
const double kDefaultPadding = 16.0;