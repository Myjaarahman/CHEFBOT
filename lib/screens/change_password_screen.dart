// lib/screens/change_password_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chefbot_app/main.dart'; // for supabase client

class ChangePasswordScreen extends StatefulWidget {
  final String email; // Needed for re-authentication

  const ChangePasswordScreen({super.key, required this.email});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // Phase 1: Verification
  final _currentPassController = TextEditingController();
  bool _isVerified = false; // Tracks if user successfully entered current password

  // Phase 2: Update
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _isLoading = false;
  bool _showPass = false; // Toggles visibility for all fields
  String? _errorText;

  final Color _primaryColor = const Color(0xFFFF5722);

  // --- Logic: Verify Current Password ---
  Future<void> _verifyCurrentPassword() async {
    final password = _currentPassController.text.trim();
    if (password.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      // Attempt to sign in to verify credentials
      final response = await supabase.auth.signInWithPassword(
        email: widget.email,
        password: password,
      );

      if (response.user != null) {
        setState(() {
          _isVerified = true; // Unlock the next step
        });
      }
    } on AuthException catch (e) {
      setState(() => _errorText = "Incorrect password.");
    } catch (e) {
      setState(() => _errorText = "An error occurred.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Logic: Set New Password ---
  Future<void> _updatePassword() async {
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    // Local Validation
    if (newPass.length < 6) {
      setState(() => _errorText = "Password must be 6+ characters.");
      return;
    }
    // Regex for 1 uppercase
    final regex = RegExp(r'^(?=.*[A-Z]).+$');
    if (!regex.hasMatch(newPass)) {
      setState(() => _errorText = "Must include at least 1 uppercase letter.");
      return;
    }
    if (newPass != confirmPass) {
      setState(() => _errorText = "Passwords do not match.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      // Update Supabase Auth
      await supabase.auth.updateUser(UserAttributes(password: newPass));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Go back
      }
    } catch (e) {
      setState(() => _errorText = "Failed to update password. Try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Helper: Text Field Builder ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool autoFocus = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        autofocus: autoFocus,
        obscureText: !_showPass,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          prefixIcon: Icon(Icons.lock_outline, color: _primaryColor),
          suffixIcon: IconButton(
            icon: Icon(_showPass ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
            onPressed: () => setState(() => _showPass = !_showPass),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Change Password", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // --- Phase 1: Verification UI ---
            if (!_isVerified) ...[
              const Text(
                "Security Check",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text("Please enter your current password to continue."),
              const SizedBox(height: 24),
              
              _buildTextField(
                controller: _currentPassController, 
                label: "Current Password",
                autoFocus: true
              ),
              
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_errorText!, style: const TextStyle(color: Colors.redAccent)),
                ),

              ElevatedButton(
                onPressed: _isLoading ? null : _verifyCurrentPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Verify & Continue", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ]

            // --- Phase 2: Update UI ---
            else ...[
              const Text(
                "Set New Password",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text("Enter your new password below."),
              const SizedBox(height: 24),

              _buildTextField(controller: _newPassController, label: "New Password", autoFocus: true),
              _buildTextField(controller: _confirmPassController, label: "Confirm Password"),

              // Requirements Hint
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Text("Requires 6+ chars & 1 uppercase letter.", style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_errorText!, style: const TextStyle(color: Colors.redAccent)),
                ),

              ElevatedButton(
                onPressed: _isLoading ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Update Password", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}