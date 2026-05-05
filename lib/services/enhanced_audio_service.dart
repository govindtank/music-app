import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../models/track_model.dart';
import '../utils/position_data.dart';
import '../services/android_auto_bridge.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';

/// Enhanced Audio Service Handler
class EnhancedAudioHandler extends BaseAudioHandler {
  static const String _queueKey = 'audio_queue';
  static const String _positionKey = 'audio_position';
  static const String _currentIndexKey = 'current_index';
  static const String _repeatModeKey = 'repeat_mode';
  static const String _shuffleModeKey = 'shuffle_mode';

  // Core services
  late AudioPlayer _audioPlayer;
  late SharedPreferences _prefs;
  late DatabaseService _databaseService;
  late ApiService _apiService;
  late AndroidAutoBridge _androidAutoBridge;

  // Audio session
  AudioSession? _audioSession;

  // Playlist management
  ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);
  List<MediaItem> _originalQueue = [];
  List<int> _shuffledIndices = [];
  bool _isShuffled = false;

  // Stream controllers
  final BehaviorSubject<List<MediaItem>> _queueSubject = 
      BehaviorSubject<List<MediaItem>>.seeded([]);
  
  final BehaviorSubject<MediaItem?> _mediaItemSubject = 
      BehaviorSubject<MediaItem?>.seeded(null);

  // Stream subscriptions
  late StreamSubscription<PlaybackEvent> _playbackEventSubscription;
  late StreamSubscription<Duration?> _durationSubscription;
  late StreamSubscription<int?> _currentIndexSubscription;
  late StreamSubscription<SequenceState?> _sequenceStateSubscription;

  // State management
  bool _isInitialized = false;
  Timer? _positionSaveTimer;

  @override
  Future<void> prepare() async {
    if (_isInitialized) return;

    try {
      // Initialize core services
      _prefs = GetIt.instance<SharedPreferences>();
      _databaseService = GetIt.instance<DatabaseService>();
      _apiService = GetIt.instance<ApiService>();
      _androidAutoBridge = AndroidAutoBridge.instance;

      // Initialize audio player with enhanced configuration
      _audioPlayer = AudioPlayer(
        audioPipeline: AudioPipeline(
          androidAudioEffects: [
            AndroidLoudnessEnhancer(),
            AndroidEqualizer(),
          ],
        ),
      );

      // Set up audio session
      await _initializeAudioSession();

      // Set up playlist
      await _audioPlayer.setAudioSource(_playlist);

      // Set up stream subscriptions
      _setupStreamSubscriptions();

      // Restore previous state
      await _restoreState();

      // Initialize Android Auto bridge
      await _initializeAndroidAutoBridge();

      _isInitialized = true;
      print('✅ Enhanced Audio Service initialized successfully');

    } catch (e) {
      print('❌ Error initializing Enhanced Audio Service: $e');
      rethrow;
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    if (!_audioPlayer.playing) {
      await stop();
      await dispose();
    }
  }

  @override
  Future<void> dispose() async {
    try {
      _positionSaveTimer?.cancel();
      
      await _saveState();
      await _playbackEventSubscription.cancel();
      await _durationSubscription.cancel();
      await _currentIndexSubscription.cancel();
      await _sequenceStateSubscription.cancel();
      
      await _audioPlayer.dispose();
      
      await _queueSubject.close();
      await _mediaItemSubject.close();
      
      _androidAutoBridge.dispose();
      
    } catch (e) {
      print('Error disposing Enhanced Audio Service: $e');
    }
    
    super.dispose();
  }

  // Audio Session Setup
  Future<void> _initializeAudioSession() async {
    try {
      _audioSession = await AudioSession.instance;
      await _audioSession!.configure(const AudioSessionConfiguration.music());

      // Handle audio interruptions
      _audioSession!.interruptionEventStream.listen((event) async {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              await _audioPlayer.setVolume(0.3);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              await pause();
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              await _audioPlayer.setVolume(1.0);
              break;
            case AudioInterruptionType.pause:
              // Optionally resume playback
              break;
            case AudioInterruptionType.unknown:
              break;
          }
        }
      });

      // Handle becoming noisy (headphones disconnected)
      _audioSession!.becomingNoisyEventStream.listen((_) {
        pause();
      });

    } catch (e) {
      print('Error initializing audio session: $e');
    }
  }

  // Stream Subscriptions Setup
  void _setupStreamSubscriptions() {
    _playbackEventSubscription = _audioPlayer.playbackEventStream.listen(
      _handlePlaybackEvent,
      onError: (error) => print('Playback event error: $error'),
    );

    _durationSubscription = _audioPlayer.durationStream.listen(
      _handleDurationChange,
      onError: (error) => print('Duration stream error: $error'),
    );

    _currentIndexSubscription = _audioPlayer.currentIndexStream.listen(
      _handleCurrentIndexChange,
      onError: (error) => print('Current index error: $error'),
    );

    _sequenceStateSubscription = _audioPlayer.sequenceStateStream.listen(
      _handleSequenceStateChange,
      onError: (error) => print('Sequence state error: $error'),
    );

    // Position saving timer
    _positionSaveTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _saveCurrentPosition(),
    );
  }

  // State Management
  Future<void> _saveState() async {
    try {
      final currentQueue = queue.value;
      final queueJson = currentQueue.map((item) => {
        'id': item.id,
        'album': item.album,
        'title': item.title,
        'artist': item.artist,
        'duration': item.duration?.inMilliseconds,
        'artUri': item.artUri?.toString(),
        'extras': item.extras,
      }).toList();

      await _prefs.setString(_queueKey, jsonEncode(queueJson));
      await _prefs.setInt(_positionKey, _audioPlayer.position.inMilliseconds);
      await _prefs.setInt(_currentIndexKey, _audioPlayer.currentIndex ?? 0);
      await _prefs.setInt(_repeatModeKey, playbackState.value.repeatMode.index);
      await _prefs.setInt(_shuffleModeKey, playbackState.value.shuffleMode.index);

    } catch (e) {
      print('Error saving audio state: $e');
    }
  }

  Future<void> _restoreState() async {
    try {
      final queueJson = _prefs.getString(_queueKey);
      if (queueJson != null) {
        final List<dynamic> queueData = jsonDecode(queueJson);
        final restoredQueue = queueData.map((item) => MediaItem(
          id: item['id'],
          album: item['album'],
          title: item['title'],
          artist: item['artist'],
          duration: item['duration'] != null 
              ? Duration(milliseconds: item['duration']) 
              : null,
          artUri: item['artUri'] != null ? Uri.parse(item['artUri']) : null,
          extras: Map<String, dynamic>.from(item['extras'] ?? {}),
        )).toList();

        if (restoredQueue.isNotEmpty) {
          await updateQueue(restoredQueue);
          
          final currentIndex = _prefs.getInt(_currentIndexKey) ?? 0;
          final position = Duration(milliseconds: _prefs.getInt(_positionKey) ?? 0);
          
          if (currentIndex < restoredQueue.length) {
            await skipToQueueItem(currentIndex);
            if (position.inMilliseconds > 0) {
              await seek(position);
            }
          }
        }
      }
    } catch (e) {
      print('Error restoring audio state: $e');
    }
  }

  void _saveCurrentPosition() {
    try {
      _prefs.setInt(_positionKey, _audioPlayer.position.inMilliseconds);
    } catch (e) {
      print('Error saving current position: $e');
    }
  }

  // Event Handlers
  Future<void> _handlePlaybackEvent(PlaybackEvent event) async {
    try {
      // Handle track completion
      if (event.processingState == ProcessingState.completed) {
        if (playbackState.value.repeatMode == AudioServiceRepeatMode.one) {
          await seek(Duration.zero);
          await play();
        } else if (hasNext) {
          await skipToNext();
        } else if (playbackState.value.repeatMode == AudioServiceRepeatMode.all) {
          await skipToQueueItem(0);
          await play();
        } else {
          await pause();
        }
      }

      // Update playback state
      await _updatePlaybackState();

      // Sync with Android Auto
      await _syncWithAndroidAuto();

    } catch (e) {
      print('Error handling playback event: $e');
    }
  }

  void _handleDurationChange(Duration? duration) {
    final currentItem = mediaItem.value;
    if (currentItem != null && duration != null) {
      final updatedItem = currentItem.copyWith(duration: duration);
      mediaItem.add(updatedItem);
      
      // Update queue item
      final currentQueue = queue.value;
      final currentIndex = _audioPlayer.currentIndex;
      if (currentIndex != null && currentIndex < currentQueue.length) {
        final updatedQueue = List<MediaItem>.from(currentQueue);
        updatedQueue[currentIndex] = updatedItem;
        queue.add(updatedQueue);
      }
    }
  }

  void _handleCurrentIndexChange(int? index) {
    if (index != null) {
      final currentQueue = queue.value;
      if (index < currentQueue.length) {
        final newMediaItem = currentQueue[index];
        mediaItem.add(newMediaItem);
        
        // Log analytics
        _trackPlayback(newMediaItem);
      }
    }
  }

  void _handleSequenceStateChange(SequenceState? sequenceState) {
    final sequence = sequenceState?.effectiveSequence;
    if (sequence != null && sequence.isNotEmpty) {
      final items = sequence
          .map((source) => source.tag as MediaItem?)
          .where((item) => item != null)
          .cast<MediaItem>()
          .toList();
      
      queue.add(items);
    }
  }

  Future<void> _updatePlaybackState() async {
    final isPlaying = _audioPlayer.playing;
    final processingState = _audioPlayer.processingState;
    
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (isPlaying) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[processingState]!,
      playing: isPlaying,
      updatePosition: _audioPlayer.position,
      bufferedPosition: _audioPlayer.bufferedPosition,
      speed: _audioPlayer.speed,
      queueIndex: _audioPlayer.currentIndex,
    ));
  }

  // Android Auto Integration
  Future<void> _initializeAndroidAutoBridge() async {
    if (Platform.isAndroid) {
      try {
        await _androidAutoBridge.initialize();
        
        // Send initial data to Android Auto
        await _syncInitialDataWithAndroidAuto();
        
        // Listen for native events
        _androidAutoBridge.playbackStateStream.listen((isPlaying) {
          if (isPlaying != _audioPlayer.playing) {
            if (isPlaying) {
              play();
            } else {
              pause();
            }
          }
        });

        _androidAutoBridge.seekPositionStream.listen((position) {
          seek(Duration(milliseconds: position));
        });

        _androidAutoBridge.skipToNextStream.listen((_) {
          skipToNext();
        });

        _androidAutoBridge.skipToPreviousStream.listen((_) {
          skipToPrevious();
        });

        _androidAutoBridge.trackChangeStream.listen((trackData) async {
          // Handle track selection from Android Auto
          final trackId = trackData['id'] as String?;
          if (trackId != null) {
            await _playTrackFromAndroidAuto(trackId, trackData);
          }
        });

      } catch (e) {
        print('Error initializing Android Auto bridge: $e');
      }
    }
  }

  /// Sync initial sections and tracks data with Android Auto
  Future<void> _syncInitialDataWithAndroidAuto() async {
    try {
      final syncData = await _apiService.getSyncData();
      
      // Send sections to Android Auto
      final sections = syncData['sections'] as List<dynamic>? ?? [];
      await _androidAutoBridge.updateSectionsData(
        sections.cast<Map<String, dynamic>>(),
      );
      
      // Send tracks grouped by sections
      final tracks = syncData['tracks'] as List<dynamic>? ?? [];
      final tracksBySection = <String, List<Map<String, dynamic>>>{};
      
      for (final track in tracks) {
        final trackMap = track as Map<String, dynamic>;
        final sectionId = trackMap['sectionId'] as String? ?? 'unknown';
        
        tracksBySection.putIfAbsent(sectionId, () => []);
        tracksBySection[sectionId]!.add(trackMap);
      }
      
      // Send playlist data for each section
      for (final entry in tracksBySection.entries) {
        await _androidAutoBridge.updatePlaylistData(entry.key, entry.value);
      }
      
      print('✅ Synced ${tracks.length} tracks across ${sections.length} sections with Android Auto');
      
    } catch (e) {
      print('❌ Error syncing initial data with Android Auto: $e');
    }
  }

  /// Handle track playback request from Android Auto
  Future<void> _playTrackFromAndroidAuto(String trackId, Map<String, dynamic> trackData) async {
    try {
      // Create MediaItem from Android Auto data
      final mediaItem = MediaItem(
        id: trackData['mediaUrl'] ?? trackId,
        title: trackData['title'] ?? 'Unknown Title',
        artist: trackData['artist'],
        album: trackData['album'],
        duration: trackData['duration'] != null 
            ? Duration(milliseconds: trackData['duration'])
            : null,
        artUri: trackData['thumbnail'] != null 
            ? Uri.tryParse(trackData['thumbnail'])
            : null,
        extras: {
          'trackId': trackId,
          'sectionId': trackData['sectionId'],
          'playable': true,
        },
      );
      
      // Load related tracks for the queue if available
      final sectionId = trackData['sectionId'] as String?;
      if (sectionId != null) {
        final sectionTracks = await _apiService.getTracksForSection(sectionId);
        final mediaItems = sectionTracks.map((track) => MediaItem(
          id: track.mediaUrl,
          title: track.title,
          artist: track.artist,
          album: track.album,
          duration: track.duration != null ? Duration(seconds: track.duration!) : null,
          artUri: track.thumbnail != null ? Uri.tryParse(track.thumbnail!) : null,
          extras: {
            'trackId': track.id,
            'sectionId': sectionId,
          },
        )).toList();
        
        // Find the index of the requested track
        final trackIndex = mediaItems.indexWhere((item) => 
          item.extras?['trackId'] == trackId);
        
        // Update queue with all tracks
        await updateQueue(mediaItems);
        
        // Skip to the requested track
        if (trackIndex >= 0) {
          await skipToQueueItem(trackIndex);
        }
      } else {
        // Play single track
        await updateQueue([mediaItem]);
      }
      
      // Start playback
      await play();
      
      // Record play in database
      await _databaseService.recordPlay(trackId);
      
      print('🎵 Playing track from Android Auto: ${mediaItem.title}');
      
    } catch (e) {
      print('❌ Error playing track from Android Auto: $e');
    }
  }

  Future<void> _syncWithAndroidAuto() async {
    if (Platform.isAndroid && _androidAutoBridge.isConnected) {
      try {
        await _androidAutoBridge.syncPlaybackState(
          isPlaying: _audioPlayer.playing,
          position: _audioPlayer.position.inMilliseconds,
          currentMediaItem: mediaItem.value,
        );
      } catch (e) {
        print('Error syncing with Android Auto: $e');
      }
    }
  }

  // Queue Management
  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    try {
      _originalQueue = List.from(newQueue);
      
      // Clear current playlist
      await _playlist.clear();
      
      // Create audio sources
      final audioSources = newQueue.map((item) => 
          AudioSource.uri(
            Uri.parse(item.id),
            tag: item,
          )
      ).toList();
      
      // Add to playlist
      await _playlist.addAll(audioSources);
      
      // Update queue stream
      queue.add(newQueue);
      
      // Update current media item if queue is not empty
      if (newQueue.isNotEmpty) {
        mediaItem.add(newQueue.first);
      }

      // Sync with Android Auto
      await _syncQueueWithAndroidAuto(newQueue);
      
    } catch (e) {
      print('Error updating queue: $e');
    }
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    try {
      final audioSource = AudioSource.uri(Uri.parse(mediaItem.id), tag: mediaItem);
      await _playlist.add(audioSource);
      
      final updatedQueue = List<MediaItem>.from(queue.value)..add(mediaItem);
      queue.add(updatedQueue);
      _originalQueue = List.from(updatedQueue);
      
    } catch (e) {
      print('Error adding queue item: $e');
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    try {
      final audioSources = mediaItems.map((item) => 
          AudioSource.uri(Uri.parse(item.id), tag: item)).toList();
      
      await _playlist.addAll(audioSources);
      
      final updatedQueue = List<MediaItem>.from(queue.value)..addAll(mediaItems);
      queue.add(updatedQueue);
      _originalQueue = List.from(updatedQueue);
      
    } catch (e) {
      print('Error adding queue items: $e');
    }
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    try {
      final audioSource = AudioSource.uri(Uri.parse(mediaItem.id), tag: mediaItem);
      await _playlist.insert(index, audioSource);
      
      final updatedQueue = List<MediaItem>.from(queue.value);
      updatedQueue.insert(index, mediaItem);
      queue.add(updatedQueue);
      _originalQueue = List.from(updatedQueue);
      
    } catch (e) {
      print('Error inserting queue item: $e');
    }
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    try {
      if (index < _playlist.length) {
        await _playlist.removeAt(index);
        
        final updatedQueue = List<MediaItem>.from(queue.value);
        updatedQueue.removeAt(index);
        queue.add(updatedQueue);
        _originalQueue = List.from(updatedQueue);
      }
    } catch (e) {
      print('Error removing queue item: $e');
    }
  }

  Future<void> _syncQueueWithAndroidAuto(List<MediaItem> queueItems) async {
    if (Platform.isAndroid && _androidAutoBridge.isConnected) {
      try {
        await _androidAutoBridge.updateQueue(queueItems);
      } catch (e) {
        print('Error syncing queue with Android Auto: $e');
      }
    }
  }

  // Playback Controls
  @override
  Future<void> play() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      print('Error starting playback: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('Error pausing playback: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping playback: $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  @override
  Future<void> skipToNext() async {
    try {
      if (hasNext) {
        await _audioPlayer.seekToNext();
      }
    } catch (e) {
      print('Error skipping to next: $e');
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      if (hasPrevious) {
        await _audioPlayer.seekToPrevious();
      }
    } catch (e) {
      print('Error skipping to previous: $e');
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    try {
      if (index >= 0 && index < queue.value.length) {
        await _audioPlayer.seek(Duration.zero, index: index);
      }
    } catch (e) {
      print('Error skipping to queue item: $e');
    }
  }

  // Repeat and Shuffle
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    try {
      final loopMode = {
        AudioServiceRepeatMode.none: LoopMode.off,
        AudioServiceRepeatMode.one: LoopMode.one,
        AudioServiceRepeatMode.all: LoopMode.all,
      }[repeatMode]!;
      
      await _audioPlayer.setLoopMode(loopMode);
      await _updatePlaybackState();
      
    } catch (e) {
      print('Error setting repeat mode: $e');
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    try {
      final enable = shuffleMode == AudioServiceShuffleMode.all;
      
      if (enable && !_isShuffled) {
        _shuffledIndices = List.generate(queue.value.length, (index) => index);
        _shuffledIndices.shuffle();
        await _audioPlayer.setShuffleModeEnabled(true);
        _isShuffled = true;
      } else if (!enable && _isShuffled) {
        await _audioPlayer.setShuffleModeEnabled(false);
        _isShuffled = false;
      }
      
      await _updatePlaybackState();
      
    } catch (e) {
      print('Error setting shuffle mode: $e');
    }
  }

  // Utilities
  bool get hasNext {
    final currentIndex = _audioPlayer.currentIndex ?? 0;
    return currentIndex < (queue.value.length - 1);
  }

  bool get hasPrevious {
    final currentIndex = _audioPlayer.currentIndex ?? 0;
    return currentIndex > 0;
  }

  // Position data stream
  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _audioPlayer.positionStream,
        _audioPlayer.bufferedPositionStream,
        _audioPlayer.durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position,
          bufferedPosition,
          duration ?? Duration.zero,
        ),
      );

  // Speed control
  @override
  Future<void> setSpeed(double speed) async {
    try {
      await _audioPlayer.setSpeed(speed);
    } catch (e) {
      print('Error setting speed: $e');
    }
  }

  // Volume control
  @override
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  // Custom actions
  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'clear_queue':
        await clearQueue();
        break;
      case 'save_state':
        await _saveState();
        break;
      case 'load_playlist':
        if (extras != null && extras.containsKey('playlistId')) {
          await _loadPlaylist(extras['playlistId']);
        }
        break;
      default:
        print('Unknown custom action: $name');
    }
  }

  Future<void> clearQueue() async {
    try {
      await _playlist.clear();
      queue.add([]);
      mediaItem.add(null);
      _originalQueue.clear();
    } catch (e) {
      print('Error clearing queue: $e');
    }
  }

  Future<void> _loadPlaylist(String playlistId) async {
    try {
      final tracks = await _apiService.getPlaylistTracks(playlistId);
      final mediaItems = tracks.map((track) => MediaItem(
        id: track.mediaUrl,
        album: track.album,
        title: track.title,
        artist: track.artist,
        duration: Duration(seconds: track.duration ?? 0),
        artUri: track.thumbnail != null ? Uri.parse(track.thumbnail!) : null,
        extras: {
          'trackId': track.id,
          'playlistId': playlistId,
          'isFavorite': track.isFavorite,
          'isDownloaded': track.isDownloaded,
        },
      )).toList();
      
      await updateQueue(mediaItems);
    } catch (e) {
      print('Error loading playlist: $e');
    }
  }

  void _trackPlayback(MediaItem mediaItem) {
    // TODO: Implement analytics tracking
    print('Now playing: ${mediaItem.title} by ${mediaItem.artist}');
  }
}

/// Enhanced Audio Service initialization
Future<AudioHandler> initEnhancedAudioService() async {
  return await AudioService.init(
    builder: () => EnhancedAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.music_app.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
      androidNotificationClickStartsActivity: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidStopForegroundOnPause: true,
      artDownscaleWidth: 200,
      artDownscaleHeight: 200,
    ),
  );
}
