// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chefbot_app/main.dart'; 
import 'package:chefbot_app/screens/login_screen.dart'; 
import 'package:chefbot_app/screens/edit_preferences_screen.dart';
import 'package:chefbot_app/screens/edit_profile_screen.dart'; // Import the new file

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _userProfileFuture;
  
  // Brand Color
  final Color _primaryColor = const Color(0xFFFF5722);

  @override
  void initState() {
    super.initState();
    _userProfileFuture = _fetchUserProfile();
  }

  // --- Logic ---
  Future<Map<String, dynamic>> _fetchUserProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw const AuthException('User not authenticated.');

    try {
      final profileData = await supabase
          .from('user_profiles')
          .select('username, email, phone_number, preferences')
          .eq('id', userId)
          .single();
      return profileData as Map<String, dynamic>;
    } catch (error) {
      throw Exception('Failed to load profile');
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error signing out')));
    }
  }

  // --- UI COMPONENTS ---

  Widget _buildSectionCard({required String title, required List<Widget> children, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title, 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChipGroup(String subtitle, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(subtitle, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _primaryColor.withOpacity(0.2)),
              ),
              child: Text(
                item,
                style: TextStyle(color: _primaryColor, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: Icon(Icons.logout, color: Colors.red.shade400),
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _primaryColor));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Could not load profile.'));
          }

          final profile = snapshot.data!;
          final preferences = profile['preferences'] as Map<String, dynamic>? ?? {};

          // Extract Data
          final dishTypes = (preferences['dishTypes'] as List<dynamic>?)?.cast<String>() ?? [];
          final specialPrefs = (preferences['specialPreferences'] as List<dynamic>?)?.cast<String>() ?? [];


          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
                // --- 1. Header with Avatar ---
                const SizedBox(height: 10),
                Center(
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _primaryColor.withOpacity(0.5), width: 2),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade100,
                          child: Icon(Icons.person, size: 50, color: Colors.grey.shade400),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Name & Email
                      Text(
                        profile['username'] ?? 'User',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.black87
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        profile['email'] ?? '',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // --- 2. Contact Details Card ---
                _buildSectionCard(
                  title: 'Contact Details',
                  trailing: IconButton(
                    icon: Icon(Icons.edit, color: _primaryColor, size: 20),
                    onPressed: () async {
                      // Navigate to Edit Screen and wait for result
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            currentEmail: profile['email'] ?? '',
                            currentPhone: profile['phone_number'] ?? '',
                            currentUsername: profile['username'] ?? '',
                          ),
                        ),
                      );

                      // If result is true (saved successfully), refresh the profile
                      if (result == true) {
                        setState(() {
                          _userProfileFuture = _fetchUserProfile();
                        });
                      }
                    },
                  ),
                  children: [
                    _buildInfoRow(Icons.email_outlined, 'Email', profile['email'] ?? 'N/A'),
                    const Divider(height: 24, thickness: 0.5),
                    _buildInfoRow(Icons.phone_iphone, 'Phone', profile['phone_number'] ?? 'N/A'),
                  ],
                ),

                // --- 3. Preferences Card ---
                _buildSectionCard(
                  title: 'Food Preferences',
                  trailing: IconButton(
                    onPressed: () async {
                      final updated = await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(builder: (_) => EditPreferencesScreen(preferences: preferences)),
                      );
                      if (updated != null) {
                        setState(() {
                          _userProfileFuture = Future.value({...profile, 'preferences': updated});
                        });
                      }
                    },
                    icon: Icon(Icons.edit, color: _primaryColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  children: [
                    if (dishTypes.isEmpty && specialPrefs.isEmpty)
                      const Text("No preferences set yet.", style: TextStyle(color: Colors.grey)),
                    
                    _buildChipGroup('Dish Types', dishTypes),
                    _buildChipGroup('Dietary Needs', specialPrefs),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // --- 4. Footer ---
                Center(
                  child: Text(
                    "ChefBot v1.0.0",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}