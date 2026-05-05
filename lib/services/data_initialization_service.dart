import 'dart:async';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/android_auto_bridge.dart';
import '../models/track_model.dart';
import '../models/section_model.dart';

class DataInitializationService {
  final ApiService _apiService;
  final DatabaseService _databaseService;
  final AndroidAutoBridge _androidAutoBridge;

  DataInitializationService({
    required ApiService apiService,
    required DatabaseService databaseService,
    required AndroidAutoBridge androidAutoBridge,
  }) : _apiService = apiService,
       _databaseService = databaseService,
       _androidAutoBridge = androidAutoBridge;

  /// Initialize all data - load from API and sync with database and Android Auto
  Future<void> initializeAllData() async {
    try {
      print('🚀 Starting data initialization...');
      
      // Step 1: Load sections from API
      final sections = await _apiService.getSections();
      print('✅ Loaded ${sections.length} sections from API');
      
      // Step 2: Save sections to database
      await _databaseService.insertSections(sections);
      print('✅ Saved sections to database');
      
      // Step 3: Load and save tracks for each section
      final allTracks = <TrackModel>[];
      
      for (final section in sections) {
        try {
          final sectionTracks = await _apiService.getTracksForSection(section.id);
          
          // Add section info to track extras
          final tracksWithSection = sectionTracks.map((track) => track.copyWith(
            extras: {
              ...track.extras ?? {},
              'sectionId': section.id,
              'sectionName': section.name,
            },
          )).toList();
          
          allTracks.addAll(tracksWithSection);
          print('✅ Loaded ${tracksWithSection.length} tracks for ${section.name}');
          
        } catch (e) {
          print('❌ Error loading tracks for ${section.name}: $e');
        }
      }
      
      // Step 4: Save all tracks to database
      if (allTracks.isNotEmpty) {
        await _databaseService.insertTracks(allTracks);
        print('✅ Saved ${allTracks.length} tracks to database');
      }
      
      // Step 5: Sync with Android Auto
      await _syncWithAndroidAuto(sections, allTracks);
      
      print('🎉 Data initialization completed successfully!');
      
    } catch (e) {
      print('❌ Error during data initialization: $e');
      rethrow;
    }
  }

  /// Refresh data - reload from API and update database and Android Auto
  Future<void> refreshData() async {
    try {
      print('🔄 Refreshing data...');
      
      // Clear cached data
      await _databaseService.clearCache();
      
      // Reinitialize
      await initializeAllData();
      
      print('🎉 Data refresh completed!');
      
    } catch (e) {
      print('❌ Error during data refresh: $e');
      rethrow;
    }
  }

  /// Sync specific section with Android Auto
  Future<void> syncSectionWithAndroidAuto(String sectionId) async {
    try {
      final section = (await _databaseService.getSections())
          .firstWhere((s) => s.id == sectionId);
      
      final tracks = await _databaseService.getTracksForSection(sectionId);
      
      // Convert tracks to Android Auto format
      final androidAutoTracks = tracks.map((track) => {
        'id': track.id,
        'title': track.title,
        'artist': track.artist,
        'album': track.album,
        'duration': track.duration != null ? track.duration! * 1000 : null, // Convert to milliseconds
        'mediaUrl': track.mediaUrl,
        'thumbnail': track.thumbnail,
        'sectionId': sectionId,
        'sectionName': section.name,
        'playable': true,
        'browsable': false,
      }).toList();
      
      // Update Android Auto with section data
      await _androidAutoBridge.updatePlaylistData(sectionId, androidAutoTracks);
      
      print('✅ Synced ${tracks.length} tracks for section ${section.name} with Android Auto');
      
    } catch (e) {
      print('❌ Error syncing section $sectionId with Android Auto: $e');
    }
  }

  /// Private method to sync all data with Android Auto
  Future<void> _syncWithAndroidAuto(List<SectionModel> sections, List<TrackModel> tracks) async {
    try {
      print('🔄 Syncing with Android Auto...');
      
      // Prepare sections data for Android Auto
      final androidAutoSections = sections.map((section) => {
        'id': section.id,
        'name': section.name,
        'description': section.description,
        'trackCount': section.trackCount ?? 0,
        'browsable': true,
        'playable': false,
        'iconUrl': section.iconUrl,
      }).toList();
      
      // Send sections to Android Auto
      await _androidAutoBridge.updateSectionsData(androidAutoSections);
      
      // Group tracks by section and send to Android Auto
      final tracksBySection = <String, List<Map<String, dynamic>>>{};
      
      for (final track in tracks) {
        final sectionId = track.extras?['sectionId'] as String? ?? 'unknown';
        final sectionName = track.extras?['sectionName'] as String? ?? 'Unknown';
        
        tracksBySection.putIfAbsent(sectionId, () => []);
        tracksBySection[sectionId]!.add({
          'id': track.id,
          'title': track.title,
          'artist': track.artist,
          'album': track.album,
          'duration': track.duration != null ? track.duration! * 1000 : null, // Convert to milliseconds
          'mediaUrl': track.mediaUrl,
          'thumbnail': track.thumbnail,
          'sectionId': sectionId,
          'sectionName': sectionName,
          'playable': true,
          'browsable': false,
        });
      }
      
      // Send tracks for each section
      for (final entry in tracksBySection.entries) {
        await _androidAutoBridge.updatePlaylistData(entry.key, entry.value);
      }
      
      print('✅ Synced ${sections.length} sections and ${tracks.length} tracks with Android Auto');
      
    } catch (e) {
      print('❌ Error syncing with Android Auto: $e');
    }
  }

  /// Get initialization status
  Future<Map<String, dynamic>> getInitializationStatus() async {
    try {
      final stats = await _databaseService.getStatistics();
      final androidAutoConnected = await _androidAutoBridge.getConnectionStatus();
      
      return {
        'sectionsCount': (await _databaseService.getSections()).length,
        'tracksCount': stats['totalTracks'],
        'favoritesCount': stats['totalFavorites'],
        'downloadsCount': stats['totalDownloads'],
        'androidAutoConnected': androidAutoConnected,
        'lastSync': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  /// Load specific playlist data
  Future<void> loadPlaylistData(String playlistId) async {
    try {
      final tracks = await _apiService.getTracksForPlaylist(playlistId);
      
      if (tracks.isNotEmpty) {
        // Add playlist info to tracks
        final tracksWithPlaylist = tracks.map((track) => track.copyWith(
          extras: {
            ...track.extras ?? {},
            'playlistId': playlistId,
          },
        )).toList();
        
        // Save to database
        await _databaseService.insertTracks(tracksWithPlaylist);
        
        print('✅ Loaded ${tracks.length} tracks for playlist $playlistId');
      }
    } catch (e) {
      print('❌ Error loading playlist $playlistId: $e');
    }
  }

  /// Validate data integrity
  Future<bool> validateDataIntegrity() async {
    try {
      // Check if we have sections
      final sections = await _databaseService.getSections();
      if (sections.isEmpty) {
        print('❌ No sections found in database');
        return false;
      }
      
      // Check if we have tracks
      final stats = await _databaseService.getStatistics();
      if (stats['totalTracks'] == 0) {
        print('❌ No tracks found in database');
        return false;
      }
      
      // Check if Android Auto bridge is working
      if (!_androidAutoBridge.isInitialized) {
        print('❌ Android Auto bridge not initialized');
        return false;
      }
      
      print('✅ Data integrity check passed');
      return true;
      
    } catch (e) {
      print('❌ Data integrity check failed: $e');
      return false;
    }
  }

  /// Auto-sync data on app startup
  Future<void> autoSync() async {
    try {
      // Check if data exists
      final stats = await _databaseService.getStatistics();
      
      if (stats['totalTracks'] == 0) {
        print('📊 No data found, performing initial sync...');
        await initializeAllData();
      } else {
        print('📊 Existing data found, syncing with Android Auto...');
        // Just sync existing data with Android Auto
        final sections = await _databaseService.getSections();
        final tracks = await _databaseService.getAllTracksWithStatus();
        await _syncWithAndroidAuto(sections, tracks);
      }
      
    } catch (e) {
      print('❌ Error during auto-sync: $e');
    }
  }

  /// Demo data population for testing
  Future<void> populateDemoData() async {
    try {
      print('🎭 Populating demo data...');
      
      // This will use the sample data from ApiService
      await initializeAllData();
      
      // Add some demo favorites and downloads
      final tracks = await _databaseService.getAllTracksWithStatus();
      
      if (tracks.isNotEmpty) {
        // Mark first 3 tracks as favorites
        for (int i = 0; i < 3 && i < tracks.length; i++) {
          await _databaseService.toggleFavorite(tracks[i].id);
        }
        
        // Mark first 2 tracks as downloaded
        for (int i = 0; i < 2 && i < tracks.length; i++) {
          await _databaseService.markAsDownloaded(tracks[i].id);
        }
        
        // Add some play history
        for (int i = 0; i < 5 && i < tracks.length; i++) {
          await _databaseService.recordPlay(tracks[i].id, duration: 30 + i * 10);
        }
        
        print('✅ Demo data populated successfully');
      }
      
    } catch (e) {
      print('❌ Error populating demo data: $e');
    }
  }
}
