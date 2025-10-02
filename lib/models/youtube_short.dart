class YouTubeShort {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String url;
  final String? description;

  const YouTubeShort({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.url,
    this.description,
  });

  // Helper method to get thumbnail URL from YouTube video ID
  static String getThumbnailUrl(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }

  // Extract video ID from YouTube shorts URL
  static String? extractVideoId(String url) {
    final RegExp regExp = RegExp(
      r'(?:youtube\.com\/shorts\/|youtu\.be\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }
}

// Sample shorts data from your provided links
class ShortsData {
  static List<YouTubeShort> getFeaturedShorts() {
    final shortUrls = [
      'https://youtube.com/shorts/T9ImysdFAZw?si=nlMjq6JYFHbf2DvZ',
      'https://youtube.com/shorts/FIQqKyFJ_xw?si=NHpmC6_At75m-RqN',
      'https://youtube.com/shorts/jn9TrsgdKU4?si=45VnfJmX_bTe38_9',
      'https://youtube.com/shorts/FIQqKyFJ_xw?si=Tx24P4jEAUWHvQ6u',
      'https://youtube.com/shorts/bBCFTx0XAiY?si=QgYF1c_zKaF7-vek',
    ];

    final shortTitles = [
      'Spiritual Wisdom #1',
      'Krishna Consciousness',
      'Bhagavad Gita Insights',
      'Daily Inspiration',
      'Sacred Knowledge',
    ];

    final List<YouTubeShort> shorts = [];
    
    for (int i = 0; i < shortUrls.length; i++) {
      final videoId = YouTubeShort.extractVideoId(shortUrls[i]);
      if (videoId != null) {
        shorts.add(
          YouTubeShort(
            id: videoId,
            title: shortTitles[i],
            thumbnailUrl: YouTubeShort.getThumbnailUrl(videoId),
            url: shortUrls[i],
            description: 'Spiritual short video ${i + 1}',
          ),
        );
      }
    }
    
    return shorts;
  }
}