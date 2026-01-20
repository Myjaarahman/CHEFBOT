// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chefbot_app/main.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Store the fetched dish types for the category chips
  List<String> _dishCategories = []; 
  
  // Store the currently selected category (e.g., 'Noodles')
  String _selectedCategory = 'All'; 
  
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserPreferences();
  }

  // --- Supabase Data Fetching Logic ---
  Future<void> _fetchUserPreferences() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _errorMessage = "User not logged in.";
        _isLoading = false;
      });
      return;
    }

    try {
      // 1. Fetch the user's entire profile
      final response = await supabase
          .from('user_profiles')
          .select('preferences') // Select only the preferences column
          .eq('id', userId)
          .single(); // Expecting one row

      // 2. Extract the JSONB data and parse the dishTypes list
      final Map<String, dynamic> preferences = response['preferences'];
      
      // We expect 'dishTypes' to be a List<dynamic> which we cast to List<String>
      final List<String> fetchedDishTypes = 
          (preferences['dishTypes'] as List<dynamic>?)?.cast<String>() ?? [];
      
      setState(() {
        // Add 'All' as the first default category, then append the user's preferences
        _dishCategories = ['All', ...fetchedDishTypes];
        _isLoading = false;
      });

    } on PostgrestException catch (error) {
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $error';
        _isLoading = false;
      });
    }
  }

  // --- UI Logic ---
  Widget _buildCategoryChip(String category) {
    final bool isSelected = category == _selectedCategory;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ActionChip(
        label: Text(category),
        onPressed: () {
          setState(() {
            _selectedCategory = category;
            // TODO: Add logic here to filter the recipes displayed below
          });
        },
        backgroundColor: isSelected ? const Color(0xFFFF5722) : Colors.grey.shade200,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(child: Text('Error loading profile: $_errorMessage')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        // Placeholder for the search bar from the mockup (Screen 3)
        title: const TextField(
          decoration: InputDecoration(
            hintText: 'Search',
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              // TODO: Navigate to the Scanner screen (Screen 5)
            },
          ),
        ],
      ),
      
      // Using a BottomNavigationBar as shown in your mockups (Screen 3)
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Infographic'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Starred'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profilo'),
        ],
        currentIndex: 0, // Assuming Home is the starting index
        selectedItemColor: const Color(0xFFFF5722),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // To show all items
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Category Chips Section (Dynamic Dish Preferences) ---
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 8.0),
            child: Text('Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 50, // Fixed height for the horizontal list
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: _dishCategories.length,
              itemBuilder: (context, index) {
                return _buildCategoryChip(_dishCategories[index]);
              },
            ),
          ),
          
          const Divider(),
          
          // --- Recipe List Area (Placeholder) ---
          const Expanded(
            child: Center(
              child: Text(
                'Recipes will appear here, filtered by your preferences!',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}