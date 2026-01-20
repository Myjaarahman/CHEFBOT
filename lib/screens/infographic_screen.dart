import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chefbot_app/widgets/infographic_image.dart'; 
// Update this import to point to where your StarredScreen file is located:
import 'starred_screen.dart'; 

// --- DETAIL SCREEN ---
class InfographicDetailView extends StatefulWidget {
  final Map<String, dynamic> data;
  const InfographicDetailView({super.key, required this.data});

  @override
  State<InfographicDetailView> createState() => _InfographicDetailViewState();
}

class _InfographicDetailViewState extends State<InfographicDetailView> {
  bool _isStarred = false;
  bool _isLoadingStar = true;
  final String _userId = Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _checkIfStarred();
  }

  // Check if this specific item is in the saved_infographics table
  Future<void> _checkIfStarred() async {
    if (_userId.isEmpty) return;
    try {
      final response = await Supabase.instance.client
          .from('saved_infographics')
          .select()
          .eq('user_id', _userId)
          .eq('infographic_id', widget.data['id'])
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isStarred = response != null;
          _isLoadingStar = false;
        });
      }
    } catch (e) {
      debugPrint("Error checking star: $e");
      if (mounted) setState(() => _isLoadingStar = false);
    }
  }

  // Toggle the star status
  Future<void> _toggleStar() async {
    if (_userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login to save tips")));
      return;
    }

    setState(() => _isStarred = !_isStarred); // Optimistic UI update

    try {
      if (_isStarred) {
        // Add to Favorites
        await Supabase.instance.client.from('saved_infographics').insert({
          'user_id': _userId,
          'infographic_id': widget.data['id'],
        });
      } else {
        // Remove from Favorites
        await Supabase.instance.client
            .from('saved_infographics')
            .delete()
            .eq('user_id', _userId)
            .eq('infographic_id', widget.data['id']);
      }
    } catch (e) {
      // Revert if error
      if (mounted) setState(() => _isStarred = !_isStarred);
      debugPrint("Error toggling star: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          (widget.data['category'] ?? 'Tip').toUpperCase(),
          style: const TextStyle(color: Colors.orange, fontSize: 14),
        ),
        actions: [
          // --- TOP RIGHT STAR BUTTON ---
          IconButton(
            onPressed: _isLoadingStar ? null : _toggleStar,
            icon: _isLoadingStar
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
                : Icon(
                    _isStarred ? Icons.star : Icons.star_border,
                    color: _isStarred ? Colors.orange : Colors.grey,
                    size: 28,
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 300,
              // UNSPLASH WIDGET
              child: InfographicImage(
                savedImageUrl: widget.data['image_url'],
                query: widget.data['title'],
                onImageSaved: (newUrl) {
                  widget.data['image_url'] = newUrl; // Local update
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.data['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(widget.data['description'] ?? '',
                      style: TextStyle(fontSize: 16, height: 1.6, color: Colors.grey[800])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- MAIN SCREEN ---
class InfographicScreen extends StatefulWidget {
  const InfographicScreen({super.key});

  @override
  State<InfographicScreen> createState() => _InfographicScreenState();
}

class _InfographicScreenState extends State<InfographicScreen> {
  final List<Map<String, dynamic>> _tips = [];
  final Set<int> _savedIds = {}; // Track which IDs are saved
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _pageSize = 5;
  final String _userId = Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _fetchUserSavedIds(); // Load user favorites to color the hearts

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMoreTips();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Fetch list of IDs the user has starred
  Future<void> _fetchUserSavedIds() async {
    if (_userId.isEmpty) return;
    try {
      final response = await Supabase.instance.client
          .from('saved_infographics')
          .select('infographic_id')
          .eq('user_id', _userId);
      
      final List<dynamic> data = response;
      if (mounted) {
        setState(() {
          _savedIds.clear();
          for (var item in data) {
            _savedIds.add(item['infographic_id']);
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching saved IDs: $e");
    }
  }

  Future<void> _toggleStar(int id) async {
    if (_userId.isEmpty) return;

    final isCurrentlySaved = _savedIds.contains(id);
    
    // Optimistic Update
    setState(() {
      if (isCurrentlySaved) {
        _savedIds.remove(id);
      } else {
        _savedIds.add(id);
      }
    });

    try {
      if (!isCurrentlySaved) {
        await Supabase.instance.client.from('saved_infographics').insert({
          'user_id': _userId,
          'infographic_id': id,
        });
      } else {
        await Supabase.instance.client
            .from('saved_infographics')
            .delete()
            .eq('user_id', _userId)
            .eq('infographic_id', id);
      }
    } catch (e) {
      // Revert on error
      setState(() {
         if (isCurrentlySaved) {
            _savedIds.add(id);
         } else {
            _savedIds.remove(id);
         }
      });
      debugPrint("Toggle error: $e");
    }
  }

  // 1. INITIAL LOAD
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('daily_tips')
          .select()
          .order('created_at', ascending: false)
          .range(0, _pageSize - 1);

      final data = List<Map<String, dynamic>>.from(response);

      if (mounted) {
        setState(() {
          _tips.clear();
          _tips.addAll(data);
          _hasMore = data.length == _pageSize;
        });

        if (data.isEmpty) _generateNewTips(isAuto: true);
      }
    } catch (e) {
      debugPrint("Error loading: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. LOAD MORE
  Future<void> _loadMoreTips() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final start = _tips.length;
      final end = start + _pageSize - 1;

      final response = await Supabase.instance.client
          .from('daily_tips')
          .select()
          .order('created_at', ascending: false)
          .range(start, end);

      final data = List<Map<String, dynamic>>.from(response);

      if (mounted) {
        setState(() {
          if (data.isEmpty) {
            _hasMore = false;
          } else {
            _tips.addAll(data);
            if (data.length < _pageSize) _hasMore = false;
          }
        });
      }
    } catch (e) {
      debugPrint("Pagination Error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  // 3. GENERATE TIPS
  Future<void> _generateNewTips({bool isAuto = false}) async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    if (!isAuto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ChefBot is writing new tips...")),
      );
    }

    try {
      final currentTitles = _tips.map((e) => e['title']).toList();
      await Supabase.instance.client.functions.invoke(
        'generate_daily_tips',
        body: {'excluded': currentTitles},
      );

      final refreshRes = await Supabase.instance.client
          .from('daily_tips')
          .select()
          .order('created_at', ascending: false)
          .limit(6);
      final freshTips = List<Map<String, dynamic>>.from(refreshRes);

      final existingIds = _tips.map((e) => e['id']).toSet();
      final uniqueFresh = freshTips.where((e) => !existingIds.contains(e['id'])).toList();

      if (mounted) {
        setState(() {
          _tips.insertAll(0, uniqueFresh);
        });
      }
    } catch (e) {
      debugPrint("Gen Error: $e");
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Kitchen Wisdom",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
                : const Icon(Icons.auto_awesome, color: Colors.orange),
            onPressed: _isGenerating ? null : () => _generateNewTips(isAuto: false),
            tooltip: "Generate New Tips",
          ),
          // --- CONNECT TO STARRED SCREEN ---
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : RefreshIndicator(
              onRefresh: () => _generateNewTips(isAuto: false),
              color: Colors.orange,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _tips.length + 1,
                itemBuilder: (context, index) {
                  if (index == _tips.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: _hasMore
                            ? const CircularProgressIndicator(color: Colors.orange)
                            : const Text("More infographics coming soon!",
                                style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }
                  return _buildInfographicCard(_tips[index]);
                },
              ),
            ),
    );
  }

  Widget _buildInfographicCard(Map<String, dynamic> item) {
    final int id = item['id'];
    final bool isStarred = _savedIds.contains(id);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          // Go to detail
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => InfographicDetailView(data: item)),
          );
          // Refresh stars when coming back
          _fetchUserSavedIds();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                children: [
                  // 1. IMAGE
                  Positioned.fill(
                    child: InfographicImage(
                      savedImageUrl: item['image_url'],
                      query: item['title'],
                      onImageSaved: (newUrl) {
                        Supabase.instance.client
                            .from('daily_tips')
                            .update({'image_url': newUrl}).eq('id', item['id']);
                        item['image_url'] = newUrl;
                      },
                    ),
                  ),
                  // 2. STAR BUTTON OVERLAY
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)
                        ]
                      ),
                      child: IconButton(
                        icon: Icon(
                          isStarred ? Icons.star : Icons.star_border,
                          color: isStarred ? Colors.orange : Colors.grey,
                        ),
                        onPressed: () => _toggleStar(id),
                        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8)),
                    child: Text((item['category'] ?? 'Tip').toUpperCase(),
                        style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Text(item['title'] ?? 'Untitled',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 8),
                  Text(item['description'] ?? '',
                      style: TextStyle(
                          color: Colors.grey[700], height: 1.5, fontSize: 15),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}