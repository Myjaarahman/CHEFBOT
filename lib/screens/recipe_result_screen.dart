import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/recipes_data.dart';
import 'recipe_detail_screen.dart';

import 'main_layout_screen.dart';
import 'infographic_screen.dart';
import 'scanner_screen.dart';
import 'starred_screen.dart';
import 'profile_screen.dart';

class RecipeResultPage extends StatefulWidget {
  final List<String> detectedIngredients;
  const RecipeResultPage({super.key, required this.detectedIngredients});

  @override
  State<RecipeResultPage> createState() => _RecipeResultPageState();
}

class _RecipeResultPageState extends State<RecipeResultPage> {
  int _currentNavIndex = 2; 
  final Color _primaryColor = const Color(0xFFE25324);

  final ScrollController _scrollController = ScrollController();
  final List<Recipe> _recipes = [];
  bool _isLoading = false;
  bool _hasMore = true;

  // --- FILTER STATE ---
  final List<String> _filters = ["All", "Breakfast", "Lunch", "Dinner", "Snack", "Dessert"];
  String _selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    _fetchRecipes();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        if (!_isLoading && _hasMore) {
          _fetchRecipes();
        }
      }
    });
  }

  void _onFilterChanged(String newFilter) {
    if (_selectedFilter == newFilter) return;
    setState(() {
      _selectedFilter = newFilter;
      _recipes.clear();
      _isLoading = true;
      _hasMore = true;
    });
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    if (_isLoading && _recipes.isNotEmpty) return;
    setState(() => _isLoading = true);

    try {
      List<String> existingTitles = _recipes.map((r) => r.title).toList();

      final response = await Supabase.instance.client.functions.invoke(
        'recipe_engine',
        body: {
          'ingredients': widget.detectedIngredients,
          'excludedRecipes': existingTitles,
          'mealType': _selectedFilter,
        },
      );

      final dynamic data = response.data;
      dynamic recipesRaw;

      if (data is Map && data.containsKey('recipes')) {
        recipesRaw = data['recipes'];
      } else if (data is List) {
        recipesRaw = data;
      } else {
        recipesRaw = [];
      }

      final List<dynamic> recipeListRaw = List<dynamic>.from(recipesRaw ?? []);

      List<Recipe> newBatch = recipeListRaw
          .map((job) => Recipe.fromJson(Map<String, dynamic>.from(job)))
          .toList();

      newBatch.sort((a, b) => a.missingIngredients.length.compareTo(b.missingIngredients.length));

      if (mounted) {
        setState(() {
          if (newBatch.isEmpty) {
            _hasMore = false;
          } else {
            _recipes.addAll(newBatch);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // --- NAVIGATION LOGIC ---
  void _onNavTap(int index) {
    if (index == _currentNavIndex && index != 0) return; // Allow 0 to go back home
    
    setState(() { _currentNavIndex = index; });
    
    Widget page;
    switch (index) {
      case 0:
        // Use pushAndRemoveUntil for Home to reset the stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
          (route) => false,
        );
        return;
      case 1: page = const InfographicScreen(); break;
      case 3: page = const StarredScreen(); break;
      case 4: page = const ProfileScreen(); break;
      default: page = const ScannerScreen(); // Case 2
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  // --- CUSTOM NAVBAR ITEM BUILDER (From Main Layout) ---
  Widget _buildNavBarItem(IconData icon, String label, int index) {
    final isSelected = _currentNavIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: isSelected ? _primaryColor : Colors.grey.shade400, 
              size: isSelected ? 28 : 26
            ),
            const SizedBox(height: 4),
            Text(
              label, 
              style: TextStyle(
                fontSize: 12, 
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, 
                color: isSelected ? _primaryColor : Colors.grey.shade400
              )
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recipe Suggestions"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      
      body: Column(
        children: [
          // --- FILTER CHIPS SECTION ---
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filterName = _filters[index];
                final isSelected = _selectedFilter == filterName;
                return ChoiceChip(
                  label: Text(filterName),
                  selected: isSelected,
                  selectedColor: _primaryColor.withOpacity(0.2),
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? _primaryColor : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? _primaryColor : Colors.transparent),
                  ),
                  onSelected: (_) => _onFilterChanged(filterName),
                );
              },
            ),
          ),

          // --- RECIPE LIST ---
          Expanded(
            child: _recipes.isEmpty && _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SpinKitFoldingCube(color: _primaryColor, size: 50.0),
                        const SizedBox(height: 30),
                        Text("Finding $_selectedFilter recipes...", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _recipes.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _recipes.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: _isLoading
                                ? SpinKitThreeBounce(color: _primaryColor, size: 25.0)
                                : _hasMore
                                    ? ElevatedButton(
                                        onPressed: _fetchRecipes,
                                        style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
                                        child: const Text("Load More", style: TextStyle(color: Colors.white)),
                                      )
                                    : const Text("No more recipes found!"),
                          ),
                        );
                      }

                      final recipe = _recipes[index];
                      final missingCount = recipe.missingIngredients.length;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecipeDetailScreen(recipe: recipe),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              // --- IMAGE WIDGET ---
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: recipe.imageUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: recipe.imageUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Center(
                                          child: SpinKitPulse(color: Colors.grey[300], size: 20),
                                        ),
                                        errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                                      )
                                    : Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.restaurant, color: Colors.grey),
                                      ),
                              ),

                              // --- CONTENT ---
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(recipe.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            missingCount == 0 ? Icons.check_circle : Icons.warning_amber,
                                            size: 16,
                                            color: missingCount == 0 ? Colors.green : Colors.orange,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            missingCount == 0 ? "Ready to cook!" : "Missing $missingCount items",
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: missingCount == 0 ? Colors.green : Colors.orange,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(right: 16),
                                child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // --- NEW FLOATING ACTION BUTTON (SCAN) ---
      floatingActionButton: SizedBox(
        height: 60,
        width: 60,
        child: FloatingActionButton(
          onPressed: () => _onNavTap(2), // 2 is the Index for Scan/Camera
          backgroundColor: _primaryColor,
          elevation: 3,
          shape: const CircleBorder(),
          child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- NEW BOTTOM APP BAR (MATCHING MAIN LAYOUT) ---
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 0.0,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black12,
        elevation: 10,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavBarItem(Icons.home_rounded, 'Home', 0),
              _buildNavBarItem(Icons.menu, 'Infographic', 1),
              // Spacer for FAB
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      "Scan",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _currentNavIndex == 2 ? FontWeight.w600 : FontWeight.w500,
                        color: _currentNavIndex == 2 ? _primaryColor : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              _buildNavBarItem(Icons.star, 'Starred', 3),
              _buildNavBarItem(Icons.person_rounded, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }
}