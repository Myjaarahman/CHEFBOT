import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:chefbot_app/screens/recipe_detail_screen.dart';
import 'package:chefbot_app/models/recipes_data.dart';

// --- NAVIGATION IMPORTS ---
import 'package:chefbot_app/screens/scanner_screen.dart';
import 'package:chefbot_app/screens/infographic_screen.dart';
import 'package:chefbot_app/screens/starred_screen.dart';
import 'package:chefbot_app/screens/profile_screen.dart';

// --- MAIN SEARCH SCREEN ---

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
  final Color _primaryColor = const Color(0xFFE25324);

  // --- SEARCH STATE ---
  bool _isLoadingMore = false;
  bool _isSearching = false;
  bool _isLoading = false;
  List<dynamic> _searchResults = [];
  int _searchPage = 0;
  bool _hasMore = true;
  
  String _activeTextQuery = "";
  List<String> _activeIngredientQuery = [];

  // --- SELECTION STATE ---
  Set<String> _selectedIngredients = {};

  // --- STATIC DATA ---
  final List<Map<String, dynamic>> _mealtimes = [
    {'label': 'Breakfast', 'icon': Icons.wb_twilight},
    {'label': 'Lunch', 'icon': Icons.wb_sunny_outlined},
    {'label': 'Dinner', 'icon': Icons.dinner_dining},
  ];

  // Full Master List
  final List<Map<String, String>> _allIngredients = [
    {'name': 'Chicken', 'emoji': '🍗'},
    {'name': 'Egg', 'emoji': '🥚'},
    {'name': 'Pasta', 'emoji': '🍝'},
    {'name': 'Beef', 'emoji': '🥩'},
    {'name': 'Rice', 'emoji': '🍚'},
    {'name': 'Potato', 'emoji': '🥔'},
    {'name': 'Salmon', 'emoji': '🐟'},
    {'name': 'Mushroom', 'emoji': '🍄'},
    {'name': 'Butter', 'emoji': '🧈'},
    {'name': 'Corn', 'emoji': '🌽'},
    {'name': 'Cheese', 'emoji': '🧀'},
    {'name': 'Broccoli', 'emoji': '🥦'},
    {'name': 'Noodles', 'emoji': '🍜'},
    {'name': 'Tomato', 'emoji': '🍅'},
    {'name': 'Spinach', 'emoji': '🍃'},
    {'name': 'Lamb', 'emoji': '🍖'},
    {'name': 'Shrimp', 'emoji': '🦐'},
    {'name': 'Milk', 'emoji': '🥛'},
    {'name': 'Onion', 'emoji': '🧅'},
    {'name': 'Carrot', 'emoji': '🥕'},
  ];

  // --- LOGIC ---

  void _onSearchPressed() {
    final textQuery = _searchController.text.trim();
    final ingredientList = _selectedIngredients.toList();

    if (textQuery.isEmpty && ingredientList.isEmpty) return;

    setState(() {
      _isSearching = true;
      _isLoading = true; // Initial full screen loading
      _searchResults = [];
      _searchPage = 0; // Reset page
      _hasMore = true;
      _activeTextQuery = textQuery;
      _activeIngredientQuery = ingredientList;
    });

    FocusScope.of(context).unfocus();
    
    // Call as new search
    _fetchSearchResults(isLoadMore: false);
  }

  Future<void> _fetchSearchResults({bool isLoadMore = false}) async {
    // 1. Set the correct loading state
    if (isLoadMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() => _isLoading = true);
    }

    try {
      // 2. Prepare the query string
      String finalQuery = _activeTextQuery;
      if (_activeIngredientQuery.isNotEmpty) {
        final ingredientsString = _activeIngredientQuery.join(" ");
        finalQuery = "$finalQuery $ingredientsString".trim();
      }

      // 3. Create list of EXISTING titles to exclude (Prevents duplicates)
      List<String> excludedTitles = isLoadMore 
          ? _searchResults.map((r) => r['title'].toString()).toList() 
          : [];

      // 4. Call Supabase
      final response = await supabase.functions.invoke('home_feed', body: {
        'query': finalQuery,
        'page': _searchPage,
        'excluded': excludedTitles, 
      });

      final data = response.data;
      final List<dynamic> newResults = data['results'] ?? [];

      if (mounted) {
        setState(() {
          if (newResults.isEmpty) {
            _hasMore = false; 
          } else {
            _searchResults.addAll(newResults);
            _searchPage++; 
          }
          
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint("Search Error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _toggleIngredient(String ingredient) {
    setState(() {
      if (_selectedIngredients.contains(ingredient)) {
        _selectedIngredients.remove(ingredient);
      } else {
        _selectedIngredients.add(ingredient);
      }
    });
  }

  void _setMealtimeSearch(String meal) {
    _searchController.text = meal;
  }

  Future<void> _navigateToViewAll() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllIngredientsScreen(
          allIngredients: _allIngredients,
          initialSelection: _selectedIngredients,
        ),
      ),
    );

    if (result != null && result is Set<String>) {
      setState(() {
        _selectedIngredients = result;
      });
    }
  }

  // --- NAVIGATION HELPER ---
  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pop(context); // Go back to Home (MainLayout)
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const InfographicScreen()));
        break;
      case 2:
        // Handled by FAB
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const StarredScreen()));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      // --- BODY ---
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isSearching ? _buildResultsList() : _buildCategoryUI(),
            ),
            if (!_isSearching) _buildBottomSearchButton(),
          ],
        ),
      ),

      // --- FLOATING ACTION BUTTON (SCANNER) ---
      floatingActionButton: SizedBox(
        height: 60, width: 60,
        child: FloatingActionButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen())),
          backgroundColor: _primaryColor,
          elevation: 3,
          shape: const CircleBorder(),
          child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0, 
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
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade400,
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

  Widget _buildNavBarItem(IconData icon, String label, int index) {
    const isSelected = false; 

    return Expanded(
      child: GestureDetector(
        onTap: () => _onBottomNavTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: isSelected ? _primaryColor : Colors.grey.shade400, 
              size: 26
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context), 
            child: const Icon(Icons.arrow_back, size: 26, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _onSearchPressed(),
              decoration: InputDecoration(
                hintText: "Search recipes...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                suffixIcon: _searchController.text.isNotEmpty || _isSearching
                    ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () => setState(() { _isSearching = false; _searchController.clear(); _selectedIngredients.clear(); }))
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryUI() {
    final previewIngredients = _allIngredients.take(8).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Mealtime", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _mealtimes.map((meal) => _buildMealtimeCard(meal)).toList(),
          ),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Include ingredients", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)),
              GestureDetector(
                onTap: _navigateToViewAll,
                child: Row(
                  children: [
                    Text("View all", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black87),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, mainAxisSpacing: 20, crossAxisSpacing: 10, childAspectRatio: 0.75,
            ),
            itemCount: previewIngredients.length,
            itemBuilder: (context, index) => _buildIngredientItem(previewIngredients[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildMealtimeCard(Map<String, dynamic> meal) {
    return GestureDetector(
      onTap: () => _setMealtimeSearch(meal['label']),
      child: Container(
        width: 105,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(meal['icon'], color: Colors.grey.shade700, size: 24),
            const SizedBox(height: 8),
            Text(meal['label'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientItem(Map<String, String> item) {
    final bool isSelected = _selectedIngredients.contains(item['name']);
    return GestureDetector(
      onTap: () => _toggleIngredient(item['name']!),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 60, width: 60,
            decoration: BoxDecoration(
              color: isSelected ? _primaryColor.withOpacity(0.15) : Colors.grey.shade100,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: _primaryColor, width: 2) : null,
            ),
            child: Center(child: Text(item['emoji']!, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(height: 8),
          Text(
            item['name']!,
            style: TextStyle(color: isSelected ? _primaryColor : Colors.grey.shade600, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSearchButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 10)]),
      child: SizedBox(
        width: double.infinity, height: 55,
        child: ElevatedButton(
          onPressed: _onSearchPressed,
          style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
          child: Text("Search Recipes (${_selectedIngredients.isEmpty ? "All" : _selectedIngredients.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isLoading) return Center(child: SpinKitWave(color: _primaryColor, size: 30));
    
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text("No recipes found", style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => setState(() { _isSearching = false; _searchController.clear(); _selectedIngredients.clear(); }),
              child: Text("Clear Search", style: TextStyle(color: _primaryColor)),
            )
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length + 1,
      itemBuilder: (context, index) {
        
        if (index == _searchResults.length) {
          if (!_hasMore) {
            return const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: Text("End of results", style: TextStyle(color: Colors.grey))),
            );
          }
          
          if (_isLoadingMore) {
             return Padding(
               padding: const EdgeInsets.all(20.0),
               child: SpinKitThreeBounce(color: _primaryColor, size: 20),
             );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
            child: ElevatedButton(
              onPressed: () => _fetchSearchResults(isLoadMore: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                foregroundColor: Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.grey.shade300)
              ),
              child: const Text("Load More Recipes"),
            ),
          );
        }
        
        return _buildResultCard(_searchResults[index]);
      },
    );
  }

  Widget _buildResultCard(dynamic data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0, color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            data['image_url'] ?? '', width: 70, height: 70, fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => Container(width: 70, height: 70, color: Colors.grey.shade200),
          ),
        ),
        title: Text(data['title'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(children: [const Icon(Icons.access_time, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(data['ready_in'] ?? '30 min', style: const TextStyle(fontSize: 12, color: Colors.grey))]),
        ),
        onTap: () {
          final recipe = Recipe(title: data['title'], imageUrl: data['image_url'] ?? "", ingredients: List<String>.from(data['ingredients'] ?? []), missingIngredients: [], steps: List<String>.from(data['steps'] ?? []));
          Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)));
        },
      ),
    );
  }
}

// --- MISSING CLASS ADDED HERE ---

class AllIngredientsScreen extends StatefulWidget {
  final List<Map<String, String>> allIngredients;
  final Set<String> initialSelection;

  const AllIngredientsScreen({
    super.key,
    required this.allIngredients,
    required this.initialSelection,
  });

  @override
  State<AllIngredientsScreen> createState() => _AllIngredientsScreenState();
}

class _AllIngredientsScreenState extends State<AllIngredientsScreen> {
  late Set<String> _currentSelection;
  late List<Map<String, String>> _filteredList;
  final TextEditingController _pantryController = TextEditingController();
  final Color _primaryColor = const Color(0xFFE25324);
  final Color _darkBtnColor = const Color(0xFF1F2937);

  @override
  void initState() {
    super.initState();
    _currentSelection = Set.from(widget.initialSelection);
    _filteredList = widget.allIngredients;
  }

  void _toggleItem(String name) {
    setState(() {
      if (_currentSelection.contains(name)) {
        _currentSelection.remove(name);
      } else {
        _currentSelection.add(name);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _currentSelection.clear();
    });
  }

  void _filterList(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = widget.allIngredients;
      } else {
        _filteredList = widget.allIngredients
            .where((item) => item['name']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  String _getEmoji(String name) {
    final item = widget.allIngredients.firstWhere(
      (element) => element['name'] == name, 
      orElse: () => {'name': name, 'emoji': '🥘'}
    );
    return item['emoji']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context), 
                      child: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                  const Text(
                    "Include ingredients",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),

            // --- SEARCH BAR ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _pantryController,
                onChanged: _filterList,
                decoration: InputDecoration(
                  hintText: "What's in your pantry?",
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: const Color(0xFFF1F8F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SELECTED SECTION ---
                    if (_currentSelection.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Selected",
                              style: TextStyle(fontSize: 18, color: Color(0xFF1F2937), fontWeight: FontWeight.w500),
                            ),
                            GestureDetector(
                              onTap: _clearAll,
                              child: Text(
                                "Clear all",
                                style: TextStyle(color: _darkBtnColor, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _currentSelection.map((name) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        height: 55, width: 55,
                                        margin: const EdgeInsets.only(top: 4, right: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(_getEmoji(name), style: const TextStyle(fontSize: 24)),
                                        ),
                                      ),
                                      Positioned(
                                        top: 0, right: 0,
                                        child: GestureDetector(
                                          onTap: () => _toggleItem(name),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF374151),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, color: Colors.white, size: 10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    name,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const Divider(height: 30, thickness: 1),
                    ],

                    // --- POPULAR GRID ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        "Popular",
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w400),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4, 
                          mainAxisSpacing: 24, 
                          crossAxisSpacing: 10, 
                          childAspectRatio: 0.70,
                        ),
                        itemCount: _filteredList.length,
                        itemBuilder: (context, index) {
                          final item = _filteredList[index];
                          final isSelected = _currentSelection.contains(item['name']);
                          
                          return GestureDetector(
                            onTap: () => _toggleItem(item['name']!),
                            child: Opacity(
                              opacity: isSelected ? 0.4 : 1.0, 
                              child: Column(
                                children: [
                                  Container(
                                    height: 60, width: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(child: Text(item['emoji']!, style: const TextStyle(fontSize: 28))),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item['name']!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w400),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 100), // Space for bottom bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      // --- BOTTOM BAR ---
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 50, width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _currentSelection);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _darkBtnColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}