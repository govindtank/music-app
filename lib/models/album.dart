import 'track.dart';

class Album {
  final String id;
  final String title;
  final String artist;
  final String? albumArt;
  final List<Track> tracks;
  final DateTime? releaseDate;
  final String? genre;
  final bool isFavourite;

  Album({
    required this.id,
    required this.title,
    required this.artist,
    this.albumArt,
    required this.tracks,
    this.releaseDate,
    this.genre,
    this.isFavourite = false,
  });

  Album copyWith({
    String? id,
    String? title,
    String? artist,
    String? albumArt,
    List<Track>? tracks,
    DateTime? releaseDate,
    String? genre,
    bool? isFavourite,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumArt: albumArt ?? this.albumArt,
      tracks: tracks ?? this.tracks,
      releaseDate: releaseDate ?? this.releaseDate,
      genre: genre ?? this.genre,
      isFavourite: isFavourite ?? this.isFavourite,
    );
  }

  Duration get totalDuration {
    return tracks.fold(
      Duration.zero,
      (duration, track) => duration + track.duration,
    );
  }

  int get trackCount => tracks.length;

  List<Track> get downloadedTracks {
    return tracks.where((track) => track.isDownloaded).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'albumArt': albumArt,
      'tracks': tracks.map((track) => track.toJson()).toList(),
      'releaseDate': releaseDate?.toIso8601String(),
      'genre': genre,
      'isFavourite': isFavourite,
    };
  }

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      albumArt: json['albumArt'],
      tracks: (json['tracks'] as List)
          .map((trackJson) => Track.fromJson(trackJson))
          .toList(),
      releaseDate: json['releaseDate'] != null 
          ? DateTime.parse(json['releaseDate']) 
          : null,
      genre: json['genre'],
      isFavourite: json['isFavourite'] ?? false,
    );
  }
}
