import 'package:flutter/material.dart';
import 'package:chefbot_app/main.dart'; // provides `supabase`

class EditPreferencesScreen extends StatefulWidget {
  final Map<String, dynamic> preferences;
  const EditPreferencesScreen({super.key, required this.preferences});

  @override
  State<EditPreferencesScreen> createState() => _EditPreferencesScreenState();
}

class _EditPreferencesScreenState extends State<EditPreferencesScreen> {
  // Brand Color
  final Color _primaryColor = const Color(0xFFFF5722);

  static const List<String> kAllDishTypes = ['Grilled', 'Fried', 'Steamed', 'Baked', 'Rice Dishes','Noodle Dishes', 'Bread Based', 'Soups & Stews', 'Salads', 'Drinks'];
  static const List<String> kAllSpecial = [
    'Kid-Friendly', 'Spicy', 'Quick & Easy', 'Healthy','Gluten-Free', 'Dairy-Free', 'Nut-Free', 'High-Protein', 
  ];


  late Set<String> _dishTypes;
  late Set<String> _specials;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final prefs = widget.preferences;

    // Safety checks for null parsing
    final dishTypesList = (prefs['dishTypes'] as List<dynamic>?)?.cast<String>() ?? [];
    final specialsList = (prefs['specialPreferences'] as List<dynamic>?)?.cast<String>() ?? [];

    _dishTypes = dishTypesList.toSet();
    _specials = specialsList.toSet();
  }

  // --- UI Components ---

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipGroup(List<String> options, Set<String> selected) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return FilterChip(
          label: Text(opt),
          selected: isSelected,
          onSelected: (val) => setState(() => val ? selected.add(opt) : selected.remove(opt)),
          
          // -- Prettier Styling --
          showCheckmark: false, // Cleaner look without the checkmark
          selectedColor: _primaryColor,
          backgroundColor: Colors.white,
          
          // Border logic: Grey border if unselected, no border if selected
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? Colors.transparent : Colors.grey.shade300,
              width: 1,
            ),
          ),
          
          // Text color logic
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildSection(String title, IconData icon, List<String> options, Set<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title, icon),
        _buildChipGroup(options, selected),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final userId = supabase.auth.currentUser?.id;
    
    if (userId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not authenticated')));
      setState(() => _saving = false);
      return;
    }

    final newPrefs = {
      'dishTypes': _dishTypes.toList(),
      'specialPreferences': _specials.toList(),
    };

    try {
      await supabase
          .from('user_profiles')
          .update({'preferences': newPrefs})
          .eq('id', userId);

      if (mounted) Navigator.pop(context, newPrefs);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Preferences',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Customize your ChefBot experience.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),

            _buildSection('Meal Type', Icons.access_time, kAllDishTypes, _dishTypes),
            
            const SizedBox(height: 32),
            const Divider(height: 1),
            const SizedBox(height: 32),

            _buildSection('Dietary Needs', Icons.health_and_safety, kAllSpecial, _specials),
            
            const SizedBox(height: 80), // Space for bottom button
          ],
        ),
      ),
      
      // -- Sticky Bottom Button --
      bottomNavigationBar: Container(
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
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            child: _saving
                ? const SizedBox(
                    height: 24, 
                    width: 24, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Text(
                    'Save Preferences',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}