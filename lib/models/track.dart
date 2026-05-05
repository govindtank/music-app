class Track {
  final String id;
  final String title;
  final String artist;
  final String albumId;
  final String? albumArt;
  final Duration duration;
  final String? audioUrl;
  final bool isDownloaded;
  final bool isFavourite;
  final DateTime? downloadedAt;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumId,
    this.albumArt,
    required this.duration,
    this.audioUrl,
    this.isDownloaded = false,
    this.isFavourite = false,
    this.downloadedAt,
  });

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? albumId,
    String? albumArt,
    Duration? duration,
    String? audioUrl,
    bool? isDownloaded,
    bool? isFavourite,
    DateTime? downloadedAt,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumId: albumId ?? this.albumId,
      albumArt: albumArt ?? this.albumArt,
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isFavourite: isFavourite ?? this.isFavourite,
      downloadedAt: downloadedAt ?? this.downloadedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'albumId': albumId,
      'albumArt': albumArt,
      'duration': duration.inMilliseconds,
      'audioUrl': audioUrl,
      'isDownloaded': isDownloaded,
      'isFavourite': isFavourite,
      'downloadedAt': downloadedAt?.toIso8601String(),
    };
  }

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      albumId: json['albumId'],
      albumArt: json['albumArt'],
      duration: Duration(milliseconds: json['duration']),
      audioUrl: json['audioUrl'],
      isDownloaded: json['isDownloaded'] ?? false,
      isFavourite: json['isFavourite'] ?? false,
      downloadedAt: json['downloadedAt'] != null 
          ? DateTime.parse(json['downloadedAt']) 
          : null,
    );
  }
}
