import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chefbot_app/models/detection_model.dart';
import '../backend/bounding_box.dart';
import 'recipe_result_screen.dart';

class IngredientResultPage extends StatefulWidget {
  final File image;
  final List<Detection> detections;
  final double imageWidth;
  final double imageHeight;

  const IngredientResultPage({
    super.key,
    required this.image,
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  State<IngredientResultPage> createState() => _IngredientResultPageState();
}

class _IngredientResultPageState extends State<IngredientResultPage> {
  late List<String> ingredients;
  final List<TextEditingController> controllers = [];
  final TextEditingController addController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // State for loading/saving process
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    ingredients = widget.detections.map((e) => e.label).toSet().toList();
    controllers.addAll(ingredients.map((s) => TextEditingController(text: s)));
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    addController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addIngredient(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    final normalized = trimmed.toLowerCase();
    final existing = ingredients.map((e) => e.toLowerCase()).toSet();
    if (existing.contains(normalized)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingredient already added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      ingredients.add(trimmed);
      controllers.add(TextEditingController(text: trimmed));
      addController.clear();
    });
    
    // Smooth scroll to the new item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _removeAt(int i) {
    setState(() {
      controllers[i].dispose();
      controllers.removeAt(i);
      ingredients.removeAt(i);
    });
  }

  Future<void> saveToSupabase([List<String>? list]) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final toSave = (list ?? ingredients)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (toSave.isEmpty) return;

    final rows = toSave.map((name) => {
      'user_id': user.id,
      'ingredient_name': name,
    }).toList();

    try {
      final resp = await Supabase.instance.client
          .from('available_ingredients')
          .insert(rows)
          .select();
      debugPrint('Inserted ${rows.length} ingredient(s) to Supabase: $resp');
    } catch (e, st) {
      debugPrint('Failed to insert ingredients to Supabase: $e\n$st');
      rethrow;
    }
  }

  Future<void> _handleFindRecipes() async {
    // Read latest values
    final sanitized = controllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    if (sanitized.isEmpty) return;

    setState(() {
      ingredients = sanitized;
      _isSaving = true;
    });

    try {
      await saveToSupabase(sanitized);
    } catch (e, st) {
      debugPrint('Failed to save ingredients: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save ingredients history, searching anyway...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeResultPage(detectedIngredients: sanitized),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              stretch: true,
              backgroundColor: theme.colorScheme.surface,
              title: const Text("Detected Ingredients"),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      widget.image,
                      fit: BoxFit.cover,
                    ),
                    // Detection Overlay
                    CustomPaint(
                      painter: BoundingBoxPainter(
                        detections: widget.detections,
                        imageWidth: widget.imageWidth,
                        imageHeight: widget.imageHeight,
                      ),
                    ),
                    // Gradient overlay for better text contrast/visual appeal
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black26,
                            Colors.transparent,
                            Colors.black54,
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Add Ingredient Field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: addController,
                textInputAction: TextInputAction.done,
                onSubmitted: _addIngredient,
                decoration: InputDecoration(
                  hintText: 'Add another ingredient...',
                  prefixIcon: const Icon(Icons.add),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () => _addIngredient(addController.text),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            
            // Ingredients List
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100), // padding for FAB
                itemCount: ingredients.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _IngredientItem(
                    key: ValueKey('${ingredients[index]}_$index'),
                    controller: controllers[index],
                    onChanged: (v) => ingredients[index] = v,
                    onDelete: () async {
                       final should = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete ingredient?'),
                          content: Text('Remove "${ingredients[index]}" from the list?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (should == true) _removeAt(index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      
      // Floating Action Button for Primary Action
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (ingredients.isEmpty || _isSaving) ? null : _handleFindRecipes,
        label: _isSaving 
          ? const SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
            )
          : const Text("Find Recipes"),
        icon: _isSaving ? null : const Icon(Icons.search),
      ),
    );
  }
}

// Separate widget for list items to keep code clean
class _IngredientItem extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;

  const _IngredientItem({
    required Key key,
    required this.controller,
    required this.onChanged,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white,
          child: Icon(Icons.restaurant_menu, size: 18, color: Colors.orange),
        ),
        title: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
          onPressed: onDelete,
          tooltip: 'Remove',
        ),
      ),
    );
  }
}