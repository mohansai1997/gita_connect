import 'package:flutter/material.dart';
import '../services/video_service.dart';

/// Dynamic Video Categories Widget - Shows all categories with videos (except Bhakti Bites)
class DynamicVideoCategoriesWidget extends StatefulWidget {
  const DynamicVideoCategoriesWidget({super.key});

  @override
  State<DynamicVideoCategoriesWidget> createState() => _DynamicVideoCategoriesWidgetState();
}

class _DynamicVideoCategoriesWidgetState extends State<DynamicVideoCategoriesWidget> {
  List<String> availableCategories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      print('DEBUG: Loading available categories...');
      final categories = await VideoService.getAvailableCategories();
      
      // Filter out Bhakti Bites since it's shown at the top
      final filteredCategories = categories.where((category) => category != 'Bhakti Bites').toList();
      
      print('DEBUG: Available categories (excluding Bhakti Bites): $filteredCategories');
      
      if (mounted) {
        setState(() {
          availableCategories = filteredCategories;
          isLoading = false;
        });
      }
    } catch (e) {
      print('ERROR loading categories: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (availableCategories.isEmpty) {
      return const SizedBox.shrink(); // Don't show anything if no categories
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: availableCategories.map((category) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header
            Text(
              category,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange.shade800,
              ),
            ),
            const SizedBox(height: 12),
            
            // Category Videos Widget
            CategoryVideosWidget(category: category),
            
            const SizedBox(height: 24),
          ],
        );
      }).toList(),
    );
  }
}

/// Widget to display videos for a specific category
class CategoryVideosWidget extends StatefulWidget {
  final String category;
  
  const CategoryVideosWidget({super.key, required this.category});

  @override
  State<CategoryVideosWidget> createState() => _CategoryVideosWidgetState();
}

class _CategoryVideosWidgetState extends State<CategoryVideosWidget> {
  List<Map<String, dynamic>> videos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      print('DEBUG: Loading videos for category: ${widget.category}');
      final categoryVideos = await VideoService.getVideosByCategory(widget.category);
      
      print('DEBUG: Loaded ${categoryVideos.length} videos for ${widget.category}');
      
      if (mounted) {
        setState(() {
          videos = categoryVideos;
          isLoading = false;
        });
      }
    } catch (e) {
      print('ERROR loading videos for ${widget.category}: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (videos.isEmpty) {
      return const SizedBox.shrink(); // Don't show anything if no videos
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          return Container(
            width: 300,
            margin: const EdgeInsets.only(right: 16),
            child: Card(
              elevation: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        image: DecorationImage(
                          image: NetworkImage(video['thumbnailUrl'] ?? ''),
                          fit: BoxFit.cover,
                          onError: (error, stackTrace) {
                            print('Error loading thumbnail for ${video['title']}: $error');
                          },
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                          // Play button
                          const Center(
                            child: Icon(
                              Icons.play_circle_outline,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Video Info
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video['title'] ?? 'Untitled',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (video['description'] != null && video['description'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              video['description'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}