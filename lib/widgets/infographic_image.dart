import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InfographicImage extends StatefulWidget {
  final String? savedImageUrl;     
  final String query;              // The search term (e.g. "Cutting Onions")
  final Function(String newUrl)? onImageSaved; 

  const InfographicImage({
    super.key, 
    this.savedImageUrl, 
    required this.query,
    this.onImageSaved,
  });

  @override
  State<InfographicImage> createState() => _InfographicImageState();
}

class _InfographicImageState extends State<InfographicImage> {
  String? _displayUrl;
  bool _isLoading = true;

  final String _unsplashAccessKey = "DyqXUCZAKJ6f5GMb4ud7Ujf5ku2iy_TCFj3pRQ8-KLw"; 

  @override
  void initState() {
    super.initState();
    if (widget.savedImageUrl != null && widget.savedImageUrl!.isNotEmpty) {
      // 1. Use saved URL (No API call)
      _displayUrl = widget.savedImageUrl;
      _isLoading = false;
    } else {
      // 2. Fetch from Unsplash
      _fetchRealPhoto();
    }
  }

  Future<void> _fetchRealPhoto() async {
    try {
      // Search for 1 landscape photo matching the query
      final url = Uri.parse(
        "https://api.unsplash.com/search/photos?query=${Uri.encodeComponent(widget.query)}&per_page=1&orientation=landscape&client_id=$_unsplashAccessKey"
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;

        if (results.isNotEmpty) {
          final String photoUrl = results[0]['urls']['small']; // 'small' is good for mobile
          
          if (mounted) {
            setState(() {
              _displayUrl = photoUrl;
              _isLoading = false;
            });
            
            // Notify parent to save this URL to Supabase
            if (widget.onImageSaved != null) {
              widget.onImageSaved!(photoUrl);
            }
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Unsplash Error: $e");
    }

    // Fallback if error or no photo found
    if (mounted) {
      setState(() {
        _displayUrl = "https://via.placeholder.com/600x400?text=Kitchen+Tip";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.grey[100],
        child: const Center(child: Icon(Icons.image, color: Colors.grey)),
      );
    }

    return Image.network(
      _displayUrl ?? "",
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (ctx, err, stack) => Container(
        color: Colors.orange[50],
        child: const Icon(Icons.broken_image, color: Colors.orange),
      ),
    );
  }
}