// lib/screens/onboarding/onboarding_special_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chefbot_app/main.dart';
import 'package:chefbot_app/models/onboarding_data.dart';
import 'package:chefbot_app/screens/main_layout_screen.dart';

class OnboardingSpecialScreen extends StatefulWidget {
  const OnboardingSpecialScreen({super.key});

  @override
  State<OnboardingSpecialScreen> createState() => _OnboardingSpecialScreenState();
}

class _OnboardingSpecialScreenState extends State<OnboardingSpecialScreen> {
  bool _isLoading = false;
  
  // Brand Color
  final Color _primaryColor = const Color(0xFFFF5722);

  // Updated Data
  final List<Map<String, String>> specialPreferences = const [
    {'name': 'Kid-Friendly', 'subtitle': 'Mild & Fun', 'emoji': '🧸'},
    {'name': 'Spicy', 'subtitle': 'Turn up the heat', 'emoji': '🌶️'}, 
    {'name': 'Quick & Easy', 'subtitle': '< 30 Minutes', 'emoji': '⚡'},
    {'name': 'Healthy', 'subtitle': 'Nutrient rich', 'emoji': '🥑'},
    {'name': 'Gluten-Free', 'subtitle': 'No Wheat/Rye', 'emoji': '🌽'},
    {'name': 'Dairy-Free', 'subtitle': 'No Lactose', 'emoji': '🥥'},
    {'name': 'Nut-Free', 'subtitle': 'Allergy safe', 'emoji': '🥜'},
    {'name': 'High-Protein', 'subtitle': 'For gains', 'emoji': '💪'},
  ];

  // --- Core Save Logic ---
  Future<void> _completeProfileAndSaveData(OnboardingData onboardingData) async {
    setState(() => _isLoading = true);

    final userDataMap = onboardingData.toSupabaseJson();
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: User not logged in.')));
      setState(() => _isLoading = false);
      return;
    }

    try {
      await supabase
          .from('user_profiles')
          .update({'preferences': userDataMap})
          .eq('id', userId);

      if (mounted) {
        _showProfileCompleteDialog();
      }
    } on PostgrestException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Database Error: ${error.message}')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An unexpected error occurred')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Success Dialog (Updated) ---
  void _showProfileCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              
              // --- CHANGED: Professional Check Icon instead of Emoji ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: _primaryColor, size: 60),
              ),
              // ---------------------------------------------------------

              const SizedBox(height: 24),
              const Text('You are all set!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Your personalized chef is ready to start cooking.', 
                textAlign: TextAlign.center, 
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: () {
                  Provider.of<OnboardingData>(context, listen: false).clearData();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Let\'s Cook!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      Expanded(child: LinearProgressIndicator(value: 1.0, color: _primaryColor, backgroundColor: Colors.grey.shade200)),
                      const SizedBox(width: 12),
                      Text("Step 3/3", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
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
                        'Any dietary needs?',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Select any specific requirements. We will filter recipes accordingly. Dont worry, you can always change it later.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- Grid Selection ---
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: specialPreferences.length,
                    itemBuilder: (context, index) {
                      final pref = specialPreferences[index];
                      final name = pref['name']!;
                      final subtitle = pref['subtitle']!;
                      final emoji = pref['emoji']!;
                      final isSelected = onboardingData.selectedSpecialPreferences.contains(name);

                      return GestureDetector(
                        onTap: () => onboardingData.toggleSpecialPreference(name),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? _primaryColor : Colors.grey.shade200,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 32)),
                              const SizedBox(height: 12),
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected ? _primaryColor : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
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
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _completeProfileAndSaveData(onboardingData),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                            'Complete Profile',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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