import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/recipes_data.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _isStarred = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfStarred();
  }

  // Check if this recipe title already exists in DB
  Future<void> _checkIfStarred() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final response = await Supabase.instance.client
        .from('saved_recipes') 
        .select()
        .eq('user_id', userId) // Check against specific user
        .eq('title', widget.recipe.title)
        .limit(1)
        .maybeSingle();

    if (mounted && response != null) {
      setState(() {
        _isStarred = true;
      });
    }
  }

  Future<void> _toggleStar() async {
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
        _showSnack("Please log in to save recipes");
        setState(() => _isLoading = false);
        return;
    }

    try {
      if (_isStarred) {
        // UN-STAR: Delete from DB
        await supabase
            .from('saved_recipes')
            .delete()
            .eq('user_id', userId)
            .eq('title', widget.recipe.title);
            
        if (mounted) setState(() => _isStarred = false);
        _showSnack("Recipe removed from Starred");
      } else {
        // STAR: Insert into DB
        // We manually construct the map to ensure image_url is saved correctly
        final Map<String, dynamic> data = {
          'user_id': userId,
          'title': widget.recipe.title,
          'ingredients': widget.recipe.ingredients,
          'steps': widget.recipe.steps,
          // CRITICAL: Save the URL we got from the Edge Function
          'image_url': widget.recipe.imageUrl, 
          // Backup keyword (using title if specific keyword isn't in model)
          'image_keyword': widget.recipe.title, 
        };

        await supabase.from('saved_recipes').insert(data);
        if (mounted) setState(() => _isStarred = true);
        _showSnack("Recipe saved!");
      }
    } catch (e) {
      _showSnack("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // --- 1. The Collapsible Image Header ---
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            backgroundColor: Colors.orange,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.recipe.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                ),
              ),
              // Use CachedNetworkImage to display the URL from Edge Function
              background: widget.recipe.imageUrl != null && widget.recipe.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.recipe.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.orange[100],
                        child: const Center(
                          child: SpinKitPulse(color: Colors.orange, size: 50.0),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.orange,
                        child: const Center(child: Icon(Icons.restaurant, size: 50, color: Colors.white)),
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.orange, Colors.deepOrange],
                        ),
                      ),
                      child: const Center(child: Icon(Icons.restaurant_menu, size: 80, color: Colors.white24)),
                    ),
            ),
            actions: [
              IconButton(
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(
                        _isStarred ? Icons.star : Icons.star_border,
                        color: _isStarred ? Colors.white : Colors.white70,
                        size: 30,
                      ),
                onPressed: _isLoading ? null : _toggleStar,
              )
            ],
          ),

          // --- 2. The Recipe Content ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Missing Ingredients Section ---
                  if (widget.recipe.missingIngredients.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("⚠️ Missing Ingredients", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.recipe.missingIngredients.map((m) => Chip(
                              label: Text(m),
                              backgroundColor: Colors.white,
                              labelStyle: const TextStyle(color: Colors.red),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // --- Ingredients List ---
                  const Text("Ingredients", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
                  const SizedBox(height: 8),
                  ...widget.recipe.ingredients.map((i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          const Icon(Icons.circle, size: 8, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(child: Text(i, style: const TextStyle(fontSize: 16))),
                        ]),
                      )),
                  const Divider(height: 40),

                  // --- Instructions ---
                  const Text("Instructions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 12),
                  ...widget.recipe.steps.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.blue[100],
                              child: Text("${e.key + 1}", style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(e.value, style: const TextStyle(fontSize: 16, height: 1.4))),
                          ],
                        ),
                      )),
                  
                  // Extra space at bottom for scrolling
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}