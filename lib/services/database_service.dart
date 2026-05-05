import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/track_model.dart';
import '../models/section_model.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'music_app.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _tracksTable = 'tracks';
  static const String _sectionsTable = 'sections';
  static const String _playlistsTable = 'playlists';
  static const String _favoritesTable = 'favorites';
  static const String _downloadsTable = 'downloads';
  static const String _playHistoryTable = 'play_history';

  Future<void> initialize() async {
    if (_database != null) return;
    
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );

    print('✅ Database initialized at: $path');
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Sections table
    await db.execute('''
      CREATE TABLE $_sectionsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        iconUrl TEXT,
        bannerUrl TEXT,
        trackCount INTEGER,
        extras TEXT,
        lastUpdated INTEGER
      )
    ''');

    // Playlists table
    await db.execute('''
      CREATE TABLE $_playlistsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        thumbnail TEXT,
        trackCount INTEGER,
        sectionId TEXT,
        dateCreated INTEGER,
        extras TEXT,
        FOREIGN KEY (sectionId) REFERENCES $_sectionsTable (id)
      )
    ''');

    // Tracks table
    await db.execute('''
      CREATE TABLE $_tracksTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT,
        album TEXT,
        genre TEXT,
        duration INTEGER,
        mediaUrl TEXT NOT NULL,
        thumbnail TEXT,
        lyrics TEXT,
        playCount INTEGER DEFAULT 0,
        dateAdded INTEGER,
        lastPlayed INTEGER,
        extras TEXT
      )
    ''');

    // Favorites table
    await db.execute('''
      CREATE TABLE $_favoritesTable (
        trackId TEXT PRIMARY KEY,
        dateAdded INTEGER,
        FOREIGN KEY (trackId) REFERENCES $_tracksTable (id)
      )
    ''');

    // Downloads table
    await db.execute('''
      CREATE TABLE $_downloadsTable (
        trackId TEXT PRIMARY KEY,
        downloadPath TEXT NOT NULL,
        dateDownloaded INTEGER,
        fileSize INTEGER,
        FOREIGN KEY (trackId) REFERENCES $_tracksTable (id)
      )
    ''');

    // Play history table
    await db.execute('''
      CREATE TABLE $_playHistoryTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trackId TEXT,
        playedAt INTEGER,
        duration INTEGER,
        FOREIGN KEY (trackId) REFERENCES $_tracksTable (id)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_tracks_title ON $_tracksTable (title)');
    await db.execute('CREATE INDEX idx_tracks_artist ON $_tracksTable (artist)');
    await db.execute('CREATE INDEX idx_play_history_played_at ON $_playHistoryTable (playedAt)');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < newVersion) {
      // Add migration logic as needed
    }
  }

  Database get database {
    if (_database == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  // Sections methods
  Future<void> insertSections(List<SectionModel> sections) async {
    final batch = database.batch();
    
    for (final section in sections) {
      batch.insert(
        _sectionsTable,
        {
          'id': section.id,
          'name': section.name,
          'description': section.description,
          'iconUrl': section.iconUrl,
          'bannerUrl': section.bannerUrl,
          'trackCount': section.trackCount,
          'extras': section.extras != null ? jsonEncode(section.extras) : null,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
  }

  Future<List<SectionModel>> getSections() async {
    final List<Map<String, dynamic>> maps = await database.query(_sectionsTable);
    
    return maps.map((map) => SectionModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      iconUrl: map['iconUrl'],
      bannerUrl: map['bannerUrl'],
      trackCount: map['trackCount'],
      extras: map['extras'] != null ? jsonDecode(map['extras']) : null,
    )).toList();
  }

  // Tracks methods
  Future<void> insertTracks(List<TrackModel> tracks) async {
    final batch = database.batch();
    
    for (final track in tracks) {
      batch.insert(
        _tracksTable,
        {
          'id': track.id,
          'title': track.title,
          'artist': track.artist,
          'album': track.album,
          'genre': track.genre,
          'duration': track.duration,
          'mediaUrl': track.mediaUrl,
          'thumbnail': track.thumbnail,
          'lyrics': track.lyrics,
          'playCount': track.playCount ?? 0,
          'dateAdded': track.dateAdded?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
          'lastPlayed': track.lastPlayed?.millisecondsSinceEpoch,
          'extras': track.extras != null ? jsonEncode(track.extras) : null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
  }

  Future<List<TrackModel>> getTracksForSection(String sectionId) async {
    // This is a simplified version - in reality you'd have a junction table
    final List<Map<String, dynamic>> maps = await database.query(
      _tracksTable,
      where: 'extras LIKE ?',
      whereArgs: ['%"sectionId":"$sectionId"%'],
    );
    
    return _mapToTracks(maps);
  }

  Future<List<TrackModel>> getTracksForPlaylist(String playlistId) async {
    // This is a simplified version - in reality you'd have a junction table
    final List<Map<String, dynamic>> maps = await database.query(
      _tracksTable,
      where: 'extras LIKE ?',
      whereArgs: ['%"playlistId":"$playlistId"%'],
    );
    
    return _mapToTracks(maps);
  }

  Future<List<TrackModel>> searchTracks(String query) async {
    final List<Map<String, dynamic>> maps = await database.query(
      _tracksTable,
      where: 'title LIKE ? OR artist LIKE ? OR album LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    
    return _mapToTracks(maps);
  }

  List<TrackModel> _mapToTracks(List<Map<String, dynamic>> maps) {
    return maps.map((map) => TrackModel(
      id: map['id'],
      title: map['title'],
      artist: map['artist'],
      album: map['album'],
      genre: map['genre'],
      duration: map['duration'],
      mediaUrl: map['mediaUrl'],
      thumbnail: map['thumbnail'],
      lyrics: map['lyrics'],
      isFavorite: false, // Will be set by join with favorites
      isDownloaded: false, // Will be set by join with downloads
      playCount: map['playCount'],
      dateAdded: map['dateAdded'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dateAdded'])
          : null,
      lastPlayed: map['lastPlayed'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastPlayed'])
          : null,
      extras: map['extras'] != null ? jsonDecode(map['extras']) : null,
    )).toList();
  }

  // Favorites methods
  Future<void> toggleFavorite(String trackId) async {
    final existing = await database.query(
      _favoritesTable,
      where: 'trackId = ?',
      whereArgs: [trackId],
    );

    if (existing.isEmpty) {
      // Add to favorites
      await database.insert(_favoritesTable, {
        'trackId': trackId,
        'dateAdded': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      // Remove from favorites
      await database.delete(
        _favoritesTable,
        where: 'trackId = ?',
        whereArgs: [trackId],
      );
    }
  }

  Future<List<TrackModel>> getFavoriteTracks() async {
    final List<Map<String, dynamic>> maps = await database.rawQuery('''
      SELECT t.*, f.dateAdded as favoriteDate
      FROM $_tracksTable t
      INNER JOIN $_favoritesTable f ON t.id = f.trackId
      ORDER BY f.dateAdded DESC
    ''');
    
    return _mapToTracks(maps).map((track) => track.copyWith(isFavorite: true)).toList();
  }

  Future<bool> isFavorite(String trackId) async {
    final result = await database.query(
      _favoritesTable,
      where: 'trackId = ?',
      whereArgs: [trackId],
    );
    return result.isNotEmpty;
  }

  // Downloads methods
  Future<void> markAsDownloaded(String trackId, {String? downloadPath, int? fileSize}) async {
    await database.insert(
      _downloadsTable,
      {
        'trackId': trackId,
        'downloadPath': downloadPath ?? '/storage/downloads/$trackId.mp3',
        'dateDownloaded': DateTime.now().millisecondsSinceEpoch,
        'fileSize': fileSize ?? 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TrackModel>> getDownloadedTracks() async {
    final List<Map<String, dynamic>> maps = await database.rawQuery('''
      SELECT t.*, d.downloadPath, d.dateDownloaded, d.fileSize
      FROM $_tracksTable t
      INNER JOIN $_downloadsTable d ON t.id = d.trackId
      ORDER BY d.dateDownloaded DESC
    ''');
    
    return _mapToTracks(maps).map((track) => track.copyWith(
      isDownloaded: true,
      downloadPath: maps.firstWhere((m) => m['id'] == track.id)['downloadPath'],
    )).toList();
  }

  Future<bool> isDownloaded(String trackId) async {
    final result = await database.query(
      _downloadsTable,
      where: 'trackId = ?',
      whereArgs: [trackId],
    );
    return result.isNotEmpty;
  }

  // Play history methods
  Future<void> recordPlay(String trackId, {int? duration}) async {
    await database.insert(_playHistoryTable, {
      'trackId': trackId,
      'playedAt': DateTime.now().millisecondsSinceEpoch,
      'duration': duration ?? 0,
    });

    // Update play count
    await database.rawUpdate('''
      UPDATE $_tracksTable 
      SET playCount = playCount + 1, lastPlayed = ?
      WHERE id = ?
    ''', [DateTime.now().millisecondsSinceEpoch, trackId]);
  }

  Future<List<TrackModel>> getRecentlyPlayedTracks({int limit = 50}) async {
    final List<Map<String, dynamic>> maps = await database.rawQuery('''
      SELECT t.*, MAX(h.playedAt) as lastPlayedAt
      FROM $_tracksTable t
      INNER JOIN $_playHistoryTable h ON t.id = h.trackId
      GROUP BY t.id
      ORDER BY lastPlayedAt DESC
      LIMIT ?
    ''', [limit]);
    
    return _mapToTracks(maps);
  }

  // Enhanced track queries with favorites and download status
  Future<List<TrackModel>> getAllTracksWithStatus() async {
    final List<Map<String, dynamic>> maps = await database.rawQuery('''
      SELECT t.*,
             CASE WHEN f.trackId IS NOT NULL THEN 1 ELSE 0 END as isFavorite,
             CASE WHEN d.trackId IS NOT NULL THEN 1 ELSE 0 END as isDownloaded,
             d.downloadPath
      FROM $_tracksTable t
      LEFT JOIN $_favoritesTable f ON t.id = f.trackId
      LEFT JOIN $_downloadsTable d ON t.id = d.trackId
    ''');
    
    return maps.map((map) => TrackModel(
      id: map['id'],
      title: map['title'],
      artist: map['artist'],
      album: map['album'],
      genre: map['genre'],
      duration: map['duration'],
      mediaUrl: map['mediaUrl'],
      thumbnail: map['thumbnail'],
      lyrics: map['lyrics'],
      isFavorite: map['isFavorite'] == 1,
      isDownloaded: map['isDownloaded'] == 1,
      downloadPath: map['downloadPath'],
      playCount: map['playCount'],
      dateAdded: map['dateAdded'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dateAdded'])
          : null,
      lastPlayed: map['lastPlayed'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastPlayed'])
          : null,
      extras: map['extras'] != null ? jsonDecode(map['extras']) : null,
    )).toList();
  }

  // Sync methods for Android Auto
  Future<Map<String, dynamic>> getSyncData() async {
    final sections = await getSections();
    final tracks = await getAllTracksWithStatus();
    
    return {
      'sections': sections.map((s) => s.toJson()).toList(),
      'tracks': tracks.map((t) => t.toJson()).toList(),
      'lastSync': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Clear methods
  Future<void> clearAllData() async {
    await database.delete(_playHistoryTable);
    await database.delete(_downloadsTable);
    await database.delete(_favoritesTable);
    await database.delete(_tracksTable);
    await database.delete(_playlistsTable);
    await database.delete(_sectionsTable);
  }

  Future<void> clearCache() async {
    await database.delete(_tracksTable);
    await database.delete(_sectionsTable);
    await database.delete(_playlistsTable);
  }

  // Statistics methods
  Future<Map<String, dynamic>> getStatistics() async {
    final List<Map<String, dynamic>> stats = await database.rawQuery('''
      SELECT 
        (SELECT COUNT(*) FROM $_tracksTable) as totalTracks,
        (SELECT COUNT(*) FROM $_favoritesTable) as totalFavorites,
        (SELECT COUNT(*) FROM $_downloadsTable) as totalDownloads,
        (SELECT COUNT(*) FROM $_playHistoryTable) as totalPlays,
        (SELECT AVG(duration) FROM $_tracksTable WHERE duration > 0) as avgDuration
    ''');
    
    if (stats.isNotEmpty) {
      return {
        'totalTracks': stats[0]['totalTracks'] ?? 0,
        'totalFavorites': stats[0]['totalFavorites'] ?? 0,
        'totalDownloads': stats[0]['totalDownloads'] ?? 0,
        'totalPlays': stats[0]['totalPlays'] ?? 0,
        'avgDuration': stats[0]['avgDuration'] ?? 0,
      };
    }
    
    return {
      'totalTracks': 0,
      'totalFavorites': 0,
      'totalDownloads': 0,
      'totalPlays': 0,
      'avgDuration': 0,
    };
  }

  // Close database
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
