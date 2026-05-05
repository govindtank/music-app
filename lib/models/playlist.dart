import 'track.dart';

class Playlist {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<Track> tracks;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isUserCreated;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.tracks,
    required this.createdAt,
    this.updatedAt,
    this.isUserCreated = true,
  });

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    List<Track>? tracks,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isUserCreated,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      tracks: tracks ?? this.tracks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isUserCreated: isUserCreated ?? this.isUserCreated,
    );
  }

  Duration get totalDuration {
    return tracks.fold(
      Duration.zero,
      (duration, track) => duration + track.duration,
    );
  }

  int get trackCount => tracks.length;

  Playlist addTrack(Track track) {
    if (tracks.any((t) => t.id == track.id)) {
      return this; // Track already exists
    }
    return copyWith(
      tracks: [...tracks, track],
      updatedAt: DateTime.now(),
    );
  }

  Playlist removeTrack(String trackId) {
    return copyWith(
      tracks: tracks.where((track) => track.id != trackId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'tracks': tracks.map((track) => track.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isUserCreated': isUserCreated,
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      tracks: (json['tracks'] as List)
          .map((trackJson) => Track.fromJson(trackJson))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      isUserCreated: json['isUserCreated'] ?? true,
    );
  }
}
