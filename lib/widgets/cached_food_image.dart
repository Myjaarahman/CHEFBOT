import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CachedFoodImage extends StatelessWidget {
  final String? savedImageUrl;     // URL from Unsplash/Supabase
  final String visualDescription;  // Kept for compatibility, serves as semantic label
  final String title;              // Kept for compatibility
  final Function(String newUrl)? onImageSaved; // Deprecated but kept to prevent errors in other files

  const CachedFoodImage({
    super.key, 
    this.savedImageUrl, 
    required this.visualDescription, 
    required this.title,
    this.onImageSaved,
  });

  @override
  Widget build(BuildContext context) {
    // 1. If we have a valid URL (which we should from Unsplash), show it.
    if (savedImageUrl != null && savedImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: savedImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        // Loading State
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: SpinKitPulse(color: Color(0xFFFF5722), size: 20.0),
          ),
        ),
        // Error State (Fallback)
        errorWidget: (context, url, error) => Container(
          color: Colors.orange[50], 
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.orange),
              SizedBox(height: 4),
              Text("No Image", style: TextStyle(color: Colors.orange, fontSize: 10))
            ],
          )
        ),
      );
    }

    // 2. Fallback if URL is completely missing (should be rare with Unsplash)
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.restaurant_menu, color: Colors.grey, size: 30),
      ),
    );
  }
}