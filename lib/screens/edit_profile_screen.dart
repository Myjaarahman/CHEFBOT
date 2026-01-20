// lib/screens/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chefbot_app/main.dart'; 
import 'package:chefbot_app/screens/change_password_screen.dart'; // Import new screen

class EditProfileScreen extends StatefulWidget {
  final String currentEmail;
  final String currentPhone;
  final String currentUsername;

  const EditProfileScreen({
    super.key,
    required this.currentEmail,
    required this.currentPhone,
    required this.currentUsername,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  bool _isLoading = false;
  bool _hasChanges = false;
  String? _emailError;
  String? _phoneError;

  final Color _primaryColor = const Color(0xFFFF5722);

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.currentEmail);
    _phoneController = TextEditingController(text: widget.currentPhone);

    _emailController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final emailChanged = _emailController.text.trim() != widget.currentEmail;
    final phoneChanged = _phoneController.text.trim() != widget.currentPhone;
    
    if ((emailChanged || phoneChanged) != _hasChanges) {
      setState(() => _hasChanges = emailChanged || phoneChanged);
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _emailError = null;
      _phoneError = null;
    });

    final newEmail = _emailController.text.trim();
    final newPhone = _phoneController.text.trim();
    final userId = supabase.auth.currentUser!.id;

    if (newEmail.isEmpty) { setState(() => _emailError = "Required"); return; }
    if (newPhone.isEmpty) { setState(() => _phoneError = "Required"); return; }

    setState(() => _isLoading = true);

    try {
      // 1. Uniqueness Check (Database)
      if (newEmail != widget.currentEmail) {
        final checkEmail = await supabase.from('user_profiles')
            .select('id').eq('email', newEmail).neq('id', userId).maybeSingle();
        if (checkEmail != null) throw "Email already in use.";
      }

      if (newPhone != widget.currentPhone) {
        final checkPhone = await supabase.from('user_profiles')
            .select('id').eq('phone_number', newPhone).neq('id', userId).maybeSingle();
        if (checkPhone != null) throw "Phone number already in use.";
      }

      // 2. Update Supabase Auth (if email changed)
      if (newEmail != widget.currentEmail) {
        await supabase.auth.updateUser(UserAttributes(email: newEmail));
      }

      // 3. Update Database Profile
      await supabase.from('user_profiles').update({
        'email': newEmail,
        'phone_number': newPhone,
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }

    } on AuthException catch (e) {
      setState(() => _emailError = e.message);
    } catch (e) {
      final msg = e.toString();
      setState(() {
        if (msg.contains("Phone")) _phoneError = "Phone number taken";
        else if (msg.contains("Email")) _emailError = "Email taken";
        else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Contact Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            
            _buildTextField(controller: _emailController, label: "Email Address", icon: Icons.email_outlined, errorText: _emailError),
            _buildTextField(controller: _phoneController, label: "Phone Number", icon: Icons.phone_android, errorText: _phoneError),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            const Text("Security", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),

            // --- CHANGE PASSWORD BUTTON ---
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.lock_reset, color: Colors.blue.shade700),
                ),
                title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Update your login password", style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  // Navigate to the Change Password Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangePasswordScreen(email: widget.currentEmail),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 40),

            // --- SAVE BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_hasChanges && !_isLoading) ? _updateProfile : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: _hasChanges ? 4 : 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: errorText != null ? Colors.redAccent : Colors.transparent),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              prefixIcon: Icon(icon, color: errorText != null ? Colors.redAccent : _primaryColor, size: 22),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(errorText, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}