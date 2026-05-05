import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';

/// Android Auto Bridge for synchronizing playback state and queue
/// between Flutter app and native Android Auto implementation
class AndroidAutoBridge {
  static const String _channelName = 'android_auto_bridge';
  static const MethodChannel _methodChannel = MethodChannel(_channelName);
  
  static AndroidAutoBridge? _instance;
  static AndroidAutoBridge get instance => _instance ??= AndroidAutoBridge._internal();
  
  AndroidAutoBridge._internal() {
    _setupMethodCallHandler();
  }

  // Stream controllers for native events
  final BehaviorSubject<bool> _playbackStateController = 
      BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<int> _seekPositionController = 
      BehaviorSubject<int>.seeded(0);
  final BehaviorSubject<void> _skipToNextController = 
      BehaviorSubject<void>();
  final BehaviorSubject<void> _skipToPreviousController = 
      BehaviorSubject<void>();
  final BehaviorSubject<Map<String, dynamic>> _trackChangeController = 
      BehaviorSubject<Map<String, dynamic>>();
  final BehaviorSubject<bool> _connectionStatusController = 
      BehaviorSubject<bool>.seeded(false);

  // Public streams
  Stream<bool> get playbackStateStream => _playbackStateController.stream;
  Stream<int> get seekPositionStream => _seekPositionController.stream;
  Stream<void> get skipToNextStream => _skipToNextController.stream;
  Stream<void> get skipToPreviousStream => _skipToPreviousController.stream;
  Stream<Map<String, dynamic>> get trackChangeStream => _trackChangeController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  // State management
  bool _isInitialized = false;
  bool _isConnected = false;
  
  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;

  /// Initialize Android Auto bridge
  Future<void> initialize() async {
    if (!Platform.isAndroid || _isInitialized) return;

    try {
      await _methodChannel.invokeMethod('initialize');
      _isInitialized = true;
      print('✅ Android Auto bridge initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Android Auto bridge: $e');
      rethrow;
    }
  }

  /// Setup method call handler for native callbacks
  void _setupMethodCallHandler() {
    _methodChannel.setMethodCallHandler((MethodCall call) async {
      try {
        switch (call.method) {
          case 'onPlaybackStateChanged':
            _handlePlaybackStateChanged(call.arguments);
            break;
            
          case 'onSeekToPosition':
            _handleSeekToPosition(call.arguments);
            break;
            
          case 'onSkipToNext':
            _handleSkipToNext();
            break;
            
          case 'onSkipToPrevious':
            _handleSkipToPrevious();
            break;
            
          case 'onTrackChanged':
            _handleTrackChanged(call.arguments);
            break;
            
          case 'onConnectionStatusChanged':
            _handleConnectionStatusChanged(call.arguments);
            break;
            
          case 'onQueueChanged':
            _handleQueueChanged(call.arguments);
            break;
            
          case 'onRepeatModeChanged':
            _handleRepeatModeChanged(call.arguments);
            break;
            
          case 'onShuffleModeChanged':
            _handleShuffleModeChanged(call.arguments);
            break;
            
          default:
            print('Unhandled method call: ${call.method}');
        }
      } catch (e) {
        print('Error handling method call ${call.method}: $e');
      }
    });
  }

  // Event handlers
  void _handlePlaybackStateChanged(dynamic arguments) {
    if (arguments is Map<String, dynamic>) {
      final isPlaying = arguments['isPlaying'] as bool? ?? false;
      _playbackStateController.add(isPlaying);
      print('🎵 Playback state from native: $isPlaying');
    }
  }

  void _handleSeekToPosition(dynamic arguments) {
    if (arguments is Map<String, dynamic>) {
      final position = arguments['position'] as int? ?? 0;
      _seekPositionController.add(position);
      print('⏭️ Seek to position from native: $position ms');
    }
  }

  void _handleSkipToNext() {
    _skipToNextController.add(null);
    print('⏭️ Skip to next from native');
  }

  void _handleSkipToPrevious() {
    _skipToPreviousController.add(null);
    print('⏮️ Skip to previous from native');
  }

  void _handleTrackChanged(dynamic arguments) {
    if (arguments is Map<String, dynamic>) {
      _trackChangeController.add(Map<String, dynamic>.from(arguments));
      print('🎵 Track changed from native: ${arguments['title']}');
    }
  }

  void _handleConnectionStatusChanged(dynamic arguments) {
    if (arguments is Map<String, dynamic>) {
      final isConnected = arguments['isConnected'] as bool? ?? false;
      _isConnected = isConnected;
      _connectionStatusController.add(isConnected);
      print('📱 Android Auto connection: $isConnected');
    }
  }

  void _handleQueueChanged(dynamic arguments) {
    // Handle queue changes from native
    print('📋 Queue changed from native');
  }

  void _handleRepeatModeChanged(dynamic arguments) {
    if (arguments is Map<String, dynamic>) {
      final repeatMode = arguments['repeatMode'] as int? ?? 0;
      print('🔁 Repeat mode changed from native: $repeatMode');
    }
  }

  void _handleShuffleModeChanged(dynamic arguments) {
    if (arguments is Map<String, dynamic>) {
      final shuffleMode = arguments['shuffleMode'] as bool? ?? false;
      print('🔀 Shuffle mode changed from native: $shuffleMode');
    }
  }

  /// Sync playback state with native Android Auto
  Future<void> syncPlaybackState({
    required bool isPlaying,
    required int position,
    MediaItem? currentMediaItem,
  }) async {
    if (!Platform.isAndroid || !_isInitialized) return;

    try {
      final arguments = {
        'isPlaying': isPlaying,
        'position': position,
        'currentMediaItem': currentMediaItem != null ? {
          'id': currentMediaItem.id,
          'title': currentMediaItem.title,
          'artist': currentMediaItem.artist,
          'album': currentMediaItem.album,
          'duration': currentMediaItem.duration?.inMilliseconds,
          'artUri': currentMediaItem.artUri?.toString(),
          'extras': currentMediaItem.extras,
        } : null,
      };

      await _methodChannel.invokeMethod('syncPlaybackState', arguments);
      
    } catch (e) {
      print('Error syncing playback state: $e');
    }
  }

  /// Update queue in native Android Auto
  Future<void> updateQueue(List<MediaItem> queue) async {
    if (!Platform.isAndroid || !_isInitialized) return;

    try {
      final queueData = queue.map((item) => {
        'id': item.id,
        'title': item.title,
        'artist': item.artist,
        'album': item.album,
        'duration': item.duration?.inMilliseconds,
        'artUri': item.artUri?.toString(),
        'extras': item.extras,
      }).toList();

      await _methodChannel.invokeMethod('updateQueue', {
        'queue': queueData,
      });
      
      print('📋 Updated queue with ${queue.length} items');
      
    } catch (e) {
      print('Error updating queue: $e');
    }
  }

  /// Legacy methods for backward compatibility
  static Future<void> updatePlaybackState({
    required String state,
    required int position,
    required double speed,
  }) async {
    await instance.syncPlaybackState(
      isPlaying: state == 'playing',
      position: position,
    );
  }
  
  static Future<void> updateMetadata({
    required String title,
    required String artist,
    required String album,
    required int duration,
  }) async {
    final mediaItem = MediaItem(
      id: 'temp_id',
      title: title,
      artist: artist,
      album: album,
      duration: Duration(milliseconds: duration),
    );
    
    await instance.syncPlaybackState(
      isPlaying: false,
      position: 0,
      currentMediaItem: mediaItem,
    );
  }
  
  static void setMethodCallHandler(Future<dynamic> Function(MethodCall call) handler) {
    instance._methodChannel.setMethodCallHandler(handler);
  }

  /// Send sections data to native for browsing
  Future<void> updateSectionsData(List<Map<String, dynamic>> sections) async {
    if (!Platform.isAndroid || !_isInitialized) return;

    try {
      await _methodChannel.invokeMethod('updateSectionsData', {
        'sections': sections,
      });
      print('📂 Updated sections data with ${sections.length} sections');
    } catch (e) {
      print('Error updating sections data: $e');
    }
  }

  /// Send playlist data to native
  Future<void> updatePlaylistData(String sectionId, List<Map<String, dynamic>> playlists) async {
    if (!Platform.isAndroid || !_isInitialized) return;

    try {
      await _methodChannel.invokeMethod('updatePlaylistData', {
        'sectionId': sectionId,
        'playlists': playlists,
      });
      print('📝 Updated playlist data for section $sectionId with ${playlists.length} playlists');
    } catch (e) {
      print('Error updating playlist data: $e');
    }
  }

  /// Notify native about queue item change
  Future<void> notifyCurrentQueueItemChanged(int index, MediaItem? mediaItem) async {
    if (!Platform.isAndroid || !_isInitialized) return;

    try {
      await _methodChannel.invokeMethod('notifyCurrentQueueItemChanged', {
        'index': index,
        'mediaItem': mediaItem != null ? {
          'id': mediaItem.id,
          'title': mediaItem.title,
          'artist': mediaItem.artist,
          'album': mediaItem.album,
          'duration': mediaItem.duration?.inMilliseconds,
          'artUri': mediaItem.artUri?.toString(),
          'extras': mediaItem.extras,
        } : null,
      });
    } catch (e) {
      print('Error notifying current queue item changed: $e');
    }
  }

  /// Sync repeat mode with native
  Future<void> syncRepeatMode(AudioServiceRepeatMode repeatMode) async {
    if (!Platform.isAndroid || !_isInitialized) return;

    try {
      int nativeRepeatMode;
      switch (repeatMode) {
        case AudioServiceRepeatMode.none:
          nativeRepeatMode = 0;
          break;
        case AudioServiceRepeatMode.one:
          nativeRepeatMode = 1;
          break;
        case AudioServiceRepeatMode.all:
          nativeRepeatMode = 2;
          break;
        default:
          nativeRepeatMode = 0;
      }

      await _methodChannel.invokeMethod('syncRepeatMode', {
        'repeatMode': nativeRepeatMode,
      });
    } catch (e) {
      print('Error syncing repeat mode: $e');
    }
  }

  /// Sync shuffle mode with native
  Future<void> syncShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (!Platform.isAndroid || !_isInitialized) return;

    try {
      final isShuffling = shuffleMode == AudioServiceShuffleMode.all;
      
      await _methodChannel.invokeMethod('syncShuffleMode', {
        'shuffleMode': isShuffling,
      });
    } catch (e) {
      print('Error syncing shuffle mode: $e');
    }
  }

  /// Get current Android Auto connection status
  Future<bool> getConnectionStatus() async {
    if (!Platform.isAndroid || !_isInitialized) return false;

    try {
      final result = await _methodChannel.invokeMethod('getConnectionStatus');
      return result as bool? ?? false;
    } catch (e) {
      print('Error getting connection status: $e');
      return false;
    }
  }

  /// Force sync all state with native
  Future<void> forceSyncState({
    required bool isPlaying,
    required int position,
    required int queueIndex,
    required MediaItem? currentMediaItem,
    required AudioServiceRepeatMode repeatMode,
    required AudioServiceShuffleMode shuffleMode,
    required List<MediaItem> queue,
  }) async {
    if (!Platform.isAndroid || !_isInitialized) return;

    try {
      // Update all state at once
      await syncPlaybackState(
        isPlaying: isPlaying,
        position: position,
        currentMediaItem: currentMediaItem,
      );
      
      await updateQueue(queue);
      
      if (currentMediaItem != null) {
        await notifyCurrentQueueItemChanged(queueIndex, currentMediaItem);
      }
      
      await syncRepeatMode(repeatMode);
      await syncShuffleMode(shuffleMode);

      print('🔄 Force synced all state with native');
      
    } catch (e) {
      print('Error force syncing state: $e');
    }
  }

  /// Debug: Get native state information
  Future<Map<String, dynamic>> getDebugInfo() async {
    if (!Platform.isAndroid || !_isInitialized) {
      return {
        'platform': 'not_android',
        'initialized': false,
      };
    }

    try {
      final result = await _methodChannel.invokeMethod('getDebugInfo');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      print('Error getting debug info: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  /// Clean up resources
  void dispose() {
    _playbackStateController.close();
    _seekPositionController.close();
    _skipToNextController.close();
    _skipToPreviousController.close();
    _trackChangeController.close();
    _connectionStatusController.close();
  }
}
