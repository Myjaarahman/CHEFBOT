class Recipe {
  final int? id;
  final String title;
  String? imageUrl; 
  final String? visualDescription;
  final List<String> ingredients;
  final List<String> missingIngredients;
  final List<String> steps;

  Recipe({
    this.id, 
    required this.title, 
    this.imageUrl,
    this.visualDescription,
    required this.ingredients, 
    required this.missingIngredients, 
    required this.steps
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      title: json['title'] ?? 'Untitled',
      // Prioritize the direct URL from Unsplash
      imageUrl: json['image_url'] ?? json['imageUrl'], 
      visualDescription: json['visual_description'] ?? json['title'], 
      ingredients: List<String>.from(json['ingredients'] ?? []),
      missingIngredients: List<String>.from(json['missing_ingredients'] ?? []),
      steps: List<String>.from(json['steps'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'image_url': imageUrl,
      'visual_description': visualDescription,
      'ingredients': ingredients,
      'missing_ingredients': missingIngredients,
      'steps': steps,
    };
  }
}