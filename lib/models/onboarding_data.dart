// lib/models/onboarding_data.dart

import 'package:flutter/material.dart';

class OnboardingData extends ChangeNotifier {


  // 2.2.2: Dish Preferences
  final List<String> _selectedDishTypes = [];
  List<String> get selectedDishTypes => _selectedDishTypes;

  // 2.2.3: Special Preferences
  final List<String> _selectedSpecialPreferences = [];
  List<String> get selectedSpecialPreferences => _selectedSpecialPreferences;

  // --- Methods to update state ---



  void toggleDishType(String dishType) {
    if (_selectedDishTypes.contains(dishType)) {
      _selectedDishTypes.remove(dishType);
    } else {
      _selectedDishTypes.add(dishType);
    }
    notifyListeners();
  }

  void toggleSpecialPreference(String preference) {
    if (_selectedSpecialPreferences.contains(preference)) {
      _selectedSpecialPreferences.remove(preference);
    } else {
      _selectedSpecialPreferences.add(preference);
    }
    notifyListeners();
  }

  // --- Method to prepare data for Supabase (JSONB) ---

  Map<String, dynamic> toSupabaseJson() {
    return {
      'dishTypes': _selectedDishTypes,
      'specialPreferences': _selectedSpecialPreferences,
    };
  }

  // Optional: Clear data if the user logs out or cancels flow
  void clearData() {
    _selectedDishTypes.clear();
    _selectedSpecialPreferences.clear();
    notifyListeners();
  }
}