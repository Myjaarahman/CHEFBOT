// lib/screens/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chefbot_app/main.dart'; 
import 'package:chefbot_app/screens/login_screen.dart';
import 'package:chefbot_app/screens/onboarding/onboarding_dish_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final FocusNode _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isPasswordFocused = false;

  String? _usernameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;

  // Colors
  final Color _primaryColor = const Color(0xFFE25324); 
  final Color _backgroundColor = const Color(0xFFFFEEE9); 

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // --- SignUp Logic ---
  Future<void> _signUp() async {
    setState(() {
      _usernameError = null;
      _emailError = null;
      _phoneError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    bool hasError = false;

    if (username.isEmpty) { _usernameError = 'Required'; hasError = true; }
    if (email.isEmpty) { _emailError = 'Required'; hasError = true; }
    if (phone.isEmpty) { _phoneError = 'Required'; hasError = true; }

    final regex = RegExp(r'^(?=.*[A-Z])[A-Za-z\d@$!%*#?&]{6,}$');
    if (!regex.hasMatch(password)) {
      _passwordError = 'Weak password';
      hasError = true;
    }

    if (password != confirmPassword) {
      _confirmPasswordError = 'Passwords do not match';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);

    try {
      final existingPhone = await supabase
          .from('user_profiles')
          .select('phone_number')
          .eq('phone_number', phone)
          .maybeSingle();

      if (existingPhone != null) {
        setState(() {
          _phoneError = 'Phone number already taken';
          _isLoading = false;
        });
        return; 
      }

      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user != null) {
        await supabase.from('user_profiles').insert({
          'id': user.id,
          'username': username,
          'email': email,
          'phone_number': phone,
        });

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingDishScreen()),
          );
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          if (error.message.toLowerCase().contains('already registered')) {
            _emailError = 'Email is already in use';
          } else {
            _showSnackBar(error.message);
          }
        });
      }
    } catch (e) {
      if (mounted) _showSnackBar('An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // --- UI Builder ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? errorText,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityToggle,
    FocusNode? focusNode,
    TextInputType? inputType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12), // Nice rounded corners
            border: Border.all(
              color: errorText != null ? Colors.redAccent.withOpacity(0.5) : Colors.grey.shade400
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: inputType,
            obscureText: isPassword && !isVisible,
            style: const TextStyle(fontSize: 14), // Readable font size
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              prefixIcon: Icon(icon, color: errorText != null ? Colors.redAccent : _primaryColor, size: 22), // Standard icon size
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey.shade400,
                        size: 22,
                      ),
                      onPressed: onVisibilityToggle,
                    )
                  : null,
              border: InputBorder.none,
              // --- CHANGED: Comfortable padding (14.0) ---
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, 
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                
                // --- 1. Logo & Titles ---
                Center(
                  child: Column(
                    children: [
                      Hero(
                        tag: 'app_logo',
                        child: Image.asset(
                          'assets/images/chefbot_logo.png',
                          height: 90, 
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'CHEFBOT',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Text(
                        'AI-BASED SMART RECIPE PLANNER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE25324),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Create your account to get started',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- 2. White Card Container ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _usernameController,
                        label: 'Username',
                        icon: Icons.person_outline,
                        errorText: _usernameError,
                      ),
                      const SizedBox(height: 16), // Comfortable spacing
                      
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        inputType: TextInputType.emailAddress,
                        errorText: _emailError,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone number',
                        icon: Icons.phone_android,
                        inputType: TextInputType.phone,
                        errorText: _phoneError,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        isVisible: _isPasswordVisible,
                        onVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        focusNode: _passwordFocusNode,
                        errorText: _passwordError,
                      ),

                      // Password Hint
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        child: _isPasswordFocused
                            ? Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.blue.shade100),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Requires 6+ chars & 1 uppercase.',
                                        style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        isVisible: _isConfirmPasswordVisible,
                        onVisibilityToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                        errorText: _confirmPasswordError,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // --- 3. Button ---
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                    shadowColor: _primaryColor.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24, 
                          width: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text('Create Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                
                const SizedBox(height: 20),

                // --- 4. Footer ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? ", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        "Log In",
                        style: TextStyle(
                          color: _primaryColor, 
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}