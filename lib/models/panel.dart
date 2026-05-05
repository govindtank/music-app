import 'album.dart';

class Panel {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final List<Album> albums;
  final PanelType type;

  Panel({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    required this.albums,
    required this.type,
  });

  Panel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    List<Album>? albums,
    PanelType? type,
  }) {
    return Panel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      albums: albums ?? this.albums,
      type: type ?? this.type,
    );
  }

  int get totalTracks {
    return albums.fold(0, (sum, album) => sum + album.trackCount);
  }

  Duration get totalDuration {
    return albums.fold(
      Duration.zero,
      (duration, album) => duration + album.totalDuration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'albums': albums.map((album) => album.toJson()).toList(),
      'type': type.toString(),
    };
  }

  factory Panel.fromJson(Map<String, dynamic> json) {
    return Panel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      albums: (json['albums'] as List)
          .map((albumJson) => Album.fromJson(albumJson))
          .toList(),
      type: PanelType.values.firstWhere(
        (type) => type.toString() == json['type'],
      ),
    );
  }
}

enum PanelType {
  featured,
  newReleases,
  topCharts,
  recommended,
  genre,
}
