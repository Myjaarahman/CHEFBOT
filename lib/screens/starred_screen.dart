import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/recipes_data.dart';
import 'recipe_detail_screen.dart';

// Define a consistent theme color
const Color kPrimaryColor = Color(0xFFFF7043); // Deep Orange
const Color kBackgroundColor = Color(0xFFF9FAFB); // Very light grey/white

class StarredScreen extends StatefulWidget {
  const StarredScreen({super.key});

  @override
  State<StarredScreen> createState() => _StarredScreenState();
}

class _StarredScreenState extends State<StarredScreen> {
  bool showRecipes = true;
  final supabase = Supabase.instance.client;

  // --- Fetch Logic (Kept same as your original) ---
  Future<List<Recipe>> _fetchStarredRecipes() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final response = await supabase
          .from('saved_recipes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (response as List<dynamic>)
          .map((map) => Recipe.fromJson(map as Map<String, dynamic>))
          .toList();
    } catch (error) {
      debugPrint("Fetch Error: $error");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchStarredInfographics() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final response = await supabase
          .from('saved_infographics')
          .select('infographic_id(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final List<dynamic> rawData = response as List<dynamic>;
      return rawData.map((item) {
        return item['infographic_id'] as Map<String, dynamic>;
      }).toList();
    } catch (error) {
      return [];
    }
  }

  // --- UI Components ---

  Widget _buildSegmentedControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      height: 50,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 212, 199),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Stack(
        children: [
          // Animated background pill
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.decelerate,
            alignment: showRecipes ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),
            ),
          ),
          // Text Labels
          Row(
            children: [
              _buildSegmentLabel("Recipes", true),
              _buildSegmentLabel("Infographics", false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentLabel(String text, bool isFirst) {
    final isSelected = isFirst ? showRecipes : !showRecipes;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => showRecipes = isFirst),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color.fromARGB(255, 0, 0, 0) : const Color.fromARGB(255, 84, 84, 84),
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: kPrimaryColor.withOpacity(0.08),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipe: recipe),
            ),
          );
          setState(() {});
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Top Image (same as infographic style) ---
            SizedBox(
              height: 150,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: recipe.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.orange[50]),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      )
                    : Container(
                        color: Colors.orange[50],
                        child: const Icon(
                          Icons.restaurant_menu,
                          size: 40,
                          color: kPrimaryColor,
                        ),
                      ),
              ),
            ),

            // --- Content ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + arrow
                  Row(
                    children: [
                      const Text(
                        'RECIPE',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  // Ingredient count pill (kept from old design)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${recipe.ingredients.length} Ingredients',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  Widget _buildInfographicCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => InfographicDetailView(data: item)),
            );
            setState(() {});
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Large Top Image
              SizedBox(
                height: 150,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: CachedNetworkImage(
                    imageUrl: item['image_url'] ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.orange[50]),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          (item['category'] ?? 'TIP').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.bookmark, color: kPrimaryColor, size: 18),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['title'] ?? 'Untitled',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Saved Items',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _buildSegmentedControl(),
          Expanded(
            child: showRecipes ? _buildRecipeList() : _buildInfographicList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeList() {
    return FutureBuilder<List<Recipe>>(
      future: _fetchStarredRecipes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return _buildLoading();
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState("No saved recipes yet!", Icons.menu_book);
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) => _buildRecipeCard(snapshot.data![index]),
        );
      },
    );
  }

  Widget _buildInfographicList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchStarredInfographics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return _buildLoading();
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState("No starred tips yet.", Icons.lightbulb_outline);
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) => _buildInfographicCard(snapshot.data![index]),
        );
      },
    );
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator(color: kPrimaryColor));

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: kPrimaryColor),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: kPrimaryColor, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// --- UPDATED: Professional Detail View using Slivers ---

class InfographicDetailView extends StatefulWidget {
  final Map<String, dynamic> data;
  const InfographicDetailView({super.key, required this.data});

  @override
  State<InfographicDetailView> createState() => _InfographicDetailViewState();
}

class _InfographicDetailViewState extends State<InfographicDetailView> {
  bool _isStarred = true;
  bool _isLoading = false;

  Future<void> _toggleStar() async {
    // ... (Your existing logic kept exactly the same for safety) ...
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final int id = widget.data['id'];

    setState(() => _isLoading = true);

    try {
      if (_isStarred) {
        await Supabase.instance.client
            .from('saved_infographics')
            .delete()
            .eq('user_id', userId)
            .eq('infographic_id', id);

        if (mounted) {
          setState(() => _isStarred = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Removed from Starred")));
        }
      } else {
        await Supabase.instance.client
            .from('saved_infographics')
            .insert({'user_id': userId, 'infographic_id': id});

        if (mounted) {
          setState(() => _isStarred = true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved to Starred!")));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. Collapsible App Bar with Image
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            // Custom Back Button style
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: widget.data['image_url'] ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.orange[50]),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image),
              ),
            ),
            actions: [
               // Floating Star Button in AppBar
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryColor))
                      : Icon(
                          _isStarred ? Icons.star : Icons.star_border,
                          color: _isStarred ? kPrimaryColor : Colors.grey,
                        ),
                  onPressed: _isLoading ? null : _toggleStar,
                ),
              )
            ],
          ),

          // 2. Content Body
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              // Rounded visual effect moving up into the image
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (widget.data['category'] ?? 'Tip').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: kPrimaryColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.data['title'] ?? 'Untitled',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.2, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  // Divider for style
                  Divider(color: Colors.grey[200], thickness: 1),
                  const SizedBox(height: 24),
                  Text(
                    widget.data['description'] ?? '',
                    style: TextStyle(fontSize: 16, height: 1.8, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 50), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}