class LectureVideo {
  final String id;
  final String title;
  final String speaker;
  final String url;
  final String thumbnailUrl;
  final String description;

  const LectureVideo({
    required this.id,
    required this.title,
    required this.speaker,
    required this.url,
    required this.thumbnailUrl,
    required this.description,
  });

  // Extract video ID from YouTube URL
  static String? extractVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]+)',
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  // Generate thumbnail URL from video ID
  static String generateThumbnailUrl(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }

  // Create LectureVideo from YouTube URL
  factory LectureVideo.fromUrl({
    required String url,
    required String title,
    required String speaker,
    String description = '',
  }) {
    final videoId = extractVideoId(url);
    if (videoId == null) {
      throw ArgumentError('Invalid YouTube URL: $url');
    }

    return LectureVideo(
      id: videoId,
      title: title,
      speaker: speaker,
      url: url,
      thumbnailUrl: generateThumbnailUrl(videoId),
      description: description,
    );
  }
}

// Static data for featured lectures
class LectureData {
  static List<LectureVideo> getFeaturedLectures() {
    return [
      LectureVideo.fromUrl(
        url: 'https://youtu.be/eM8XJthiuOI?si=dtxZuXtSISs9oh7z',
        title: 'Bhagavad Gita Chapter 1: Complete Analysis',
        speaker: 'HG Amogh Lila Prabhu',
        description: 'Deep dive into the first chapter of Bhagavad Gita with practical insights for spiritual life.',
      ),
      LectureVideo.fromUrl(
        url: 'https://youtu.be/42nPznBptXg?si=bBir8fqM6OT1w2y0',
        title: 'The Science of Self-Realization',
        speaker: 'HG Gauranga Prabhu',
        description: 'Understanding the eternal soul and its relationship with the Supreme through Vedic wisdom.',
      ),
      LectureVideo.fromUrl(
        url: 'https://youtu.be/VdH9CV7Cp5c?si=bwFRr1SKMrerIkUB',
        title: 'Krishna Consciousness in Modern Life',
        speaker: 'HG Radhanath Swami',
        description: 'How to apply ancient spiritual principles in contemporary daily living.',
      ),
    ];
  }
}