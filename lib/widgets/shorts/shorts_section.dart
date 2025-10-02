import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../models/youtube_short.dart';

class ShortsSection extends StatefulWidget {
  const ShortsSection({super.key});

  @override
  State<ShortsSection> createState() => _ShortsSectionState();
}

class _ShortsSectionState extends State<ShortsSection> {
  final PageController _pageController = PageController();
  final List<YouTubeShort> _shorts = ShortsData.getFeaturedShorts();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Spiritual Shorts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all shorts page
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Horizontal Scrollable Shorts
          SizedBox(
            height: 200, // Height for shorts thumbnails
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _shorts.length,
              itemBuilder: (context, index) {
                final short = _shorts[index];
                return Container(
                  width: 120, // Width for each short
                  margin: const EdgeInsets.only(right: 12),
                  child: ShortThumbnailCard(
                    short: short,
                    onTap: () => _playShort(short),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _playShort(YouTubeShort short) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => YouTubePlayerDialog(short: short),
    );
  }
}

class ShortThumbnailCard extends StatelessWidget {
  final YouTubeShort short;
  final VoidCallback onTap;

  const ShortThumbnailCard({
    super.key,
    required this.short,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Thumbnail Image
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: short.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_fill,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Shorts',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
              
              // Play Button
              Center(
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    size: 30,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              
              // Title at Bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    short.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              // Shorts Icon
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Shorts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class YouTubePlayerDialog extends StatefulWidget {
  final YouTubeShort short;

  const YouTubePlayerDialog({super.key, required this.short});

  @override
  State<YouTubePlayerDialog> createState() => _YouTubePlayerDialogState();
}

class _YouTubePlayerDialogState extends State<YouTubePlayerDialog> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.short.id,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        loop: false,
        forceHD: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.black87,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.short.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // YouTube Player
            Expanded(
              child: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.red,
                progressColors: const ProgressBarColors(
                  playedColor: Colors.red,
                  handleColor: Colors.redAccent,
                ),
                bottomActions: [
                  CurrentPosition(),
                  ProgressBar(
                    isExpanded: true,
                    colors: const ProgressBarColors(
                      playedColor: Colors.red,
                      handleColor: Colors.redAccent,
                    ),
                  ),
                  RemainingDuration(),
                  FullScreenButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}