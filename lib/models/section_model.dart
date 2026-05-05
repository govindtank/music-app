class SectionModel {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final String? bannerUrl;
  final int? trackCount;
  final List<PlaylistModel>? playlists;
  final Map<String, dynamic>? extras;

  const SectionModel({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    this.bannerUrl,
    this.trackCount,
    this.playlists,
    this.extras,
  });

  SectionModel copyWith({
    String? id,
    String? name,
    String? description,
    String? iconUrl,
    String? bannerUrl,
    int? trackCount,
    List<PlaylistModel>? playlists,
    Map<String, dynamic>? extras,
  }) {
    return SectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      trackCount: trackCount ?? this.trackCount,
      playlists: playlists ?? this.playlists,
      extras: extras ?? this.extras,
    );
  }

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id'] ?? json['sId'] ?? '',
      name: json['name'] ?? 'Unknown Section',
      description: json['description'],
      iconUrl: json['iconUrl'] ?? json['icon'],
      bannerUrl: json['bannerUrl'] ?? json['banner'],
      trackCount: json['trackCount']?.toInt(),
      playlists: json['playlists'] != null 
          ? (json['playlists'] as List)
              .map((p) => PlaylistModel.fromJson(p))
              .toList()
          : null,
      extras: json['extras'] != null 
          ? Map<String, dynamic>.from(json['extras'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'bannerUrl': bannerUrl,
      'trackCount': trackCount,
      'playlists': playlists?.map((p) => p.toJson()).toList(),
      'extras': extras,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SectionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SectionModel(id: $id, name: $name, trackCount: $trackCount)';
  }
}

class PlaylistModel {
  final String id;
  final String name;
  final String? description;
  final String? thumbnail;
  final int? trackCount;
  final String? sectionId;
  final DateTime? dateCreated;
  final Map<String, dynamic>? extras;

  const PlaylistModel({
    required this.id,
    required this.name,
    this.description,
    this.thumbnail,
    this.trackCount,
    this.sectionId,
    this.dateCreated,
    this.extras,
  });

  PlaylistModel copyWith({
    String? id,
    String? name,
    String? description,
    String? thumbnail,
    int? trackCount,
    String? sectionId,
    DateTime? dateCreated,
    Map<String, dynamic>? extras,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      thumbnail: thumbnail ?? this.thumbnail,
      trackCount: trackCount ?? this.trackCount,
      sectionId: sectionId ?? this.sectionId,
      dateCreated: dateCreated ?? this.dateCreated,
      extras: extras ?? this.extras,
    );
  }

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'] ?? json['sId'] ?? '',
      name: json['name'] ?? 'Unknown Playlist',
      description: json['description'],
      thumbnail: json['thumbnail'] ?? json['artUri'],
      trackCount: json['trackCount']?.toInt(),
      sectionId: json['sectionId'],
      dateCreated: json['dateCreated'] != null 
          ? DateTime.parse(json['dateCreated'])
          : null,
      extras: json['extras'] != null 
          ? Map<String, dynamic>.from(json['extras'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'thumbnail': thumbnail,
      'trackCount': trackCount,
      'sectionId': sectionId,
      'dateCreated': dateCreated?.toIso8601String(),
      'extras': extras,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaylistModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PlaylistModel(id: $id, name: $name, trackCount: $trackCount)';
  }
}
