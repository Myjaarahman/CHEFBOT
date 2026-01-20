// lib/screens/onboarding/onboarding_dish_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chefbot_app/models/onboarding_data.dart';
import 'package:chefbot_app/screens/onboarding/onboarding_special_screen.dart'; 

class OnboardingDishScreen extends StatelessWidget {
  const OnboardingDishScreen({super.key});

  // Updated to use Emojis for consistency with the previous screen
  final List<Map<String, String>> dishTypes = const [
    {'name': 'Grilled', 'subtitle': 'BBQ, Grilled Meats & Veggies', 'emoji': '🍖'},
    {'name': 'Fried', 'subtitle': 'Crispy & Golden Delights', 'emoji': '🍗'},
    {'name': 'Steamed', 'subtitle': 'Healthy Steam Cooking', 'emoji': '🥟'},
    {'name': 'Baked', 'subtitle': 'Oven-Fresh Goodness', 'emoji': '🥧'},
    {'name': 'Rice Dishes', 'subtitle': 'Biryani, Fried Rice, Risotto', 'emoji': '🍚'},
    {'name': 'Noodle Dishes', 'subtitle': 'Ramen, Pasta, Pad Thai', 'emoji': '🍜'},
    {'name': 'Bread Based', 'subtitle': 'Sandwiches, Pizza, Flatbreads', 'emoji': '🥪'},
    {'name': 'Soups & Stews', 'subtitle': 'Hearty Broths, Curries, Stews', 'emoji': '🥣'},
    {'name': 'Salads', 'subtitle': 'Fresh Greens, Fruit Salads', 'emoji': '🥗'},
    {'name': 'Drinks', 'subtitle': 'Beverages, Smoothies, Teas', 'emoji': '🍹'},
  ];

  @override
  Widget build(BuildContext context) {
    // Brand Color
    final primaryColor = const Color(0xFFFF5722);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<OnboardingData>(
          builder: (context, onboardingData, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
                // --- Top Progress Bar ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    children: [
                      // Progress 0.66 for Step 2 of 3
                      Expanded(child: LinearProgressIndicator(value: 0.66, color: primaryColor, backgroundColor: Colors.grey.shade200)),
                      const SizedBox(width: 12),
                      Text("Step 2/3", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                // --- Header Text ---
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What dishes excite you?',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Select the types of cooking styles and dishes you prefer. Dont worry, you can always change it later.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- List Selection ---
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                    itemCount: dishTypes.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final dish = dishTypes[index];
                      final name = dish['name']!;
                      final subtitle = dish['subtitle']!;
                      final emoji = dish['emoji']!;
                      final isSelected = onboardingData.selectedDishTypes.contains(name);

                      return GestureDetector(
                        onTap: () => onboardingData.toggleDishType(name),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor.withOpacity(0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? primaryColor : Colors.grey.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Emoji Container
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(emoji, style: const TextStyle(fontSize: 28)),
                              ),
                              const SizedBox(width: 16),
                              
                              // Text Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? primaryColor : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Selection Checkbox Indicator
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? primaryColor : Colors.transparent,
                                  border: isSelected 
                                      ? null 
                                      : Border.all(color: Colors.grey.shade300, width: 2),
                                ),
                                child: isSelected 
                                    ? const Icon(Icons.check, size: 16, color: Colors.white) 
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // --- Bottom Button ---
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: onboardingData.selectedDishTypes.isNotEmpty
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const OnboardingSpecialScreen()),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      onboardingData.selectedDishTypes.isEmpty
                          ? 'Select at least one'
                          : 'Continue (${onboardingData.selectedDishTypes.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}