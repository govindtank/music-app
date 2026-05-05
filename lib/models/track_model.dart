class TrackModel {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? duration; // in seconds
  final String mediaUrl;
  final String? thumbnail;
  final String? lyrics;
  final bool isFavorite;
  final bool isDownloaded;
  final String? downloadPath;
  final DateTime? dateAdded;
  final DateTime? lastPlayed;
  final int? playCount;
  final Map<String, dynamic>? extras;

  const TrackModel({
    required this.id,
    required this.title,
    required this.mediaUrl,
    this.artist,
    this.album,
    this.genre,
    this.duration,
    this.thumbnail,
    this.lyrics,
    this.isFavorite = false,
    this.isDownloaded = false,
    this.downloadPath,
    this.dateAdded,
    this.lastPlayed,
    this.playCount,
    this.extras,
  });

  TrackModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? genre,
    int? duration,
    String? mediaUrl,
    String? thumbnail,
    String? lyrics,
    bool? isFavorite,
    bool? isDownloaded,
    String? downloadPath,
    DateTime? dateAdded,
    DateTime? lastPlayed,
    int? playCount,
    Map<String, dynamic>? extras,
  }) {
    return TrackModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      duration: duration ?? this.duration,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnail: thumbnail ?? this.thumbnail,
      lyrics: lyrics ?? this.lyrics,
      isFavorite: isFavorite ?? this.isFavorite,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadPath: downloadPath ?? this.downloadPath,
      dateAdded: dateAdded ?? this.dateAdded,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      playCount: playCount ?? this.playCount,
      extras: extras ?? this.extras,
    );
  }

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    return TrackModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      artist: json['artist'],
      album: json['album'],
      genre: json['genre'],
      duration: json['duration']?.toInt(),
      mediaUrl: json['mediaUrl'] ?? json['url'] ?? '',
      thumbnail: json['thumbnail'] ?? json['artUri'],
      lyrics: json['lyrics'],
      isFavorite: json['isFavorite'] ?? false,
      isDownloaded: json['isDownloaded'] ?? false,
      downloadPath: json['downloadPath'],
      dateAdded: json['dateAdded'] != null 
          ? DateTime.parse(json['dateAdded'])
          : null,
      lastPlayed: json['lastPlayed'] != null 
          ? DateTime.parse(json['lastPlayed'])
          : null,
      playCount: json['playCount']?.toInt(),
      extras: json['extras'] != null 
          ? Map<String, dynamic>.from(json['extras'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'genre': genre,
      'duration': duration,
      'mediaUrl': mediaUrl,
      'thumbnail': thumbnail,
      'lyrics': lyrics,
      'isFavorite': isFavorite,
      'isDownloaded': isDownloaded,
      'downloadPath': downloadPath,
      'dateAdded': dateAdded?.toIso8601String(),
      'lastPlayed': lastPlayed?.toIso8601String(),
      'playCount': playCount,
      'extras': extras,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TrackModel(id: $id, title: $title, artist: $artist, album: $album)';
  }
}
