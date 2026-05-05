import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:get_it/get_it.dart';
import '../services/audio_service.dart';
import '../screens/now_playing_screen.dart';
import '../utils/position_data.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({Key? key}) : super(key: key);

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  late AudioHandler _audioHandler;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  bool _isExpanded = false;
  bool _isDragging = false;
  double _dragStartY = 0;
  double _currentDragY = 0;

  // Mini player height when collapsed
  static const double miniPlayerHeight = 70.0;
  static const double expandedPlayerHeight = 0.9; // 90% of screen height

  @override
  void initState() {
    super.initState();
    _audioHandler = GetIt.instance<AudioHandler>();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _expandPlayer() {
    if (!_isExpanded) {
      setState(() => _isExpanded = true);
      _animationController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _collapsePlayer() {
    if (_isExpanded) {
      setState(() => _isExpanded = false);
      _animationController.reverse();
      HapticFeedback.lightImpact();
    }
  }

  void _togglePlayer() {
    if (_isExpanded) {
      _collapsePlayer();
    } else {
      _expandPlayer();
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _isDragging = true;
    _dragStartY = details.globalPosition.dy;
    _currentDragY = _dragStartY;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    
    _currentDragY = details.globalPosition.dy;
    double dragDistance = _dragStartY - _currentDragY;
    
    // Calculate drag progress (0.0 to 1.0)
    double dragProgress = dragDistance / (MediaQuery.of(context).size.height * 0.3);
    dragProgress = dragProgress.clamp(0.0, 1.0);
    
    if (_isExpanded) {
      // When expanded, dragging down should collapse
      double reverseProgress = 1.0 - (-dragDistance / (MediaQuery.of(context).size.height * 0.3));
      reverseProgress = reverseProgress.clamp(0.0, 1.0);
      _animationController.value = reverseProgress;
    } else {
      // When collapsed, dragging up should expand
      _animationController.value = dragProgress;
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;
    
    double dragDistance = _dragStartY - _currentDragY;
    double velocity = details.velocity.pixelsPerSecond.dy;
    
    // Determine if we should expand or collapse based on drag distance and velocity
    bool shouldExpand;
    
    if (_isExpanded) {
      // When expanded, collapse if dragged down significantly or with downward velocity
      shouldExpand = !(dragDistance < -100 || velocity > 300);
    } else {
      // When collapsed, expand if dragged up significantly or with upward velocity  
      shouldExpand = dragDistance > 100 || velocity < -300;
    }
    
    if (shouldExpand && !_isExpanded) {
      _expandPlayer();
    } else if (!shouldExpand && _isExpanded) {
      _collapsePlayer();
    } else {
      // Return to current state
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: _audioHandler.mediaItem,
      builder: (context, mediaItemSnapshot) {
        final mediaItem = mediaItemSnapshot.data;
        if (mediaItem == null) {
          return const SizedBox.shrink();
        }

        return AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            final screenHeight = MediaQuery.of(context).size.height;
            final expandedHeight = screenHeight * expandedPlayerHeight;
            final currentHeight = miniPlayerHeight + 
                (_slideAnimation.value * (expandedHeight - miniPlayerHeight));

            return Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: currentHeight,
              child: GestureDetector(
                onPanStart: _handleDragStart,
                onPanUpdate: _handleDragUpdate,
                onPanEnd: _handleDragEnd,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(3.w),
                      topRight: Radius.circular(3.w),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: _slideAnimation.value < 0.5 
                      ? _buildMiniPlayer(mediaItem)
                      : _buildExpandedPlayer(mediaItem),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMiniPlayer(MediaItem mediaItem) {
    return InkWell(
      onTap: _expandPlayer,
      child: Container(
        height: miniPlayerHeight,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
        child: Row(
          children: [
            // Album Art
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2.w),
                child: mediaItem.artUri != null
                    ? CachedNetworkImage(
                        imageUrl: mediaItem.artUri.toString(),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.music_note, color: Colors.grey),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.music_note, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note, color: Colors.grey),
                      ),
              ),
            ),
            
            SizedBox(width: 3.w),
            
            // Track Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    mediaItem.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    mediaItem.artist ?? 'Unknown Artist',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Play/Pause Button
            StreamBuilder<PlaybackState>(
              stream: _audioHandler.playbackState,
              builder: (context, playbackSnapshot) {
                final playbackState = playbackSnapshot.data;
                final isPlaying = playbackState?.playing ?? false;
                final processingState = playbackState?.processingState;
                
                return IconButton(
                  onPressed: () {
                    if (isPlaying) {
                      _audioHandler.pause();
                    } else {
                      _audioHandler.play();
                    }
                  },
                  icon: _buildPlayPauseIcon(isPlaying, processingState),
                );
              },
            ),
            
            // Next Button
            IconButton(
              onPressed: () => _audioHandler.skipToNext(),
              icon: Icon(
                Icons.skip_next,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedPlayer(MediaItem mediaItem) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 12.w,
            height: 0.5.h,
            margin: EdgeInsets.only(bottom: 2.h),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2.w),
            ),
          ),
          
          // Header with Close Button
          Row(
            children: [
              IconButton(
                onPressed: _collapsePlayer,
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
              Expanded(
                child: Text(
                  'Now Playing',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: () {
                  // Navigate to full now playing screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NowPlayingScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
          
          SizedBox(height: 4.h),
          
          // Large Album Art
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 8.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.w),
                child: mediaItem.artUri != null
                    ? CachedNetworkImage(
                        imageUrl: mediaItem.artUri.toString(),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.music_note, size: 80, color: Colors.grey),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.music_note, size: 80, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note, size: 80, color: Colors.grey),
                      ),
              ),
            ),
          ),
          
          SizedBox(height: 3.h),
          
          // Track Information
          Text(
            mediaItem.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: 1.h),
          
          Text(
            mediaItem.artist ?? 'Unknown Artist',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: 3.h),
          
          // Progress Bar
          StreamBuilder<PositionData>(
            stream: _getPositionDataStream(),
            builder: (context, snapshot) {
              final positionData = snapshot.data;
              return Column(
                children: [
                  Slider(
                    value: positionData?.position.inMilliseconds.toDouble() ?? 0.0,
                    max: positionData?.duration.inMilliseconds.toDouble() ?? 1.0,
                    onChanged: (value) {
                      _audioHandler.seek(Duration(milliseconds: value.toInt()));
                    },
                    activeColor: Theme.of(context).primaryColor,
                    inactiveColor: Colors.grey[300],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(positionData?.position ?? Duration.zero),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          _formatDuration(positionData?.duration ?? Duration.zero),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          
          SizedBox(height: 2.h),
          
          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Shuffle
              StreamBuilder<bool>(
                stream: _audioHandler.playbackState
                    .map((state) => state.shuffleMode == AudioServiceShuffleMode.all)
                    .distinct(),
                builder: (context, snapshot) {
                  final isShuffling = snapshot.data ?? false;
                  return IconButton(
                    onPressed: () {
                      _audioHandler.setShuffleMode(
                        isShuffling 
                            ? AudioServiceShuffleMode.none 
                            : AudioServiceShuffleMode.all,
                      );
                    },
                    icon: Icon(
                      Icons.shuffle,
                      color: isShuffling 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey,
                    ),
                  );
                },
              ),
              
              // Previous
              IconButton(
                onPressed: () => _audioHandler.skipToPrevious(),
                icon: const Icon(Icons.skip_previous, size: 32),
              ),
              
              // Play/Pause
              StreamBuilder<PlaybackState>(
                stream: _audioHandler.playbackState,
                builder: (context, snapshot) {
                  final playbackState = snapshot.data;
                  final isPlaying = playbackState?.playing ?? false;
                  final processingState = playbackState?.processingState;
                  
                  return Container(
                    width: 16.w,
                    height: 16.w,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        if (isPlaying) {
                          _audioHandler.pause();
                        } else {
                          _audioHandler.play();
                        }
                      },
                      icon: _buildPlayPauseIcon(
                        isPlaying, 
                        processingState,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
              
              // Next
              IconButton(
                onPressed: () => _audioHandler.skipToNext(),
                icon: const Icon(Icons.skip_next, size: 32),
              ),
              
              // Repeat
              StreamBuilder<AudioServiceRepeatMode>(
                stream: _audioHandler.playbackState
                    .map((state) => state.repeatMode)
                    .distinct(),
                builder: (context, snapshot) {
                  final repeatMode = snapshot.data ?? AudioServiceRepeatMode.none;
                  return IconButton(
                    onPressed: () {
                      final nextMode = repeatMode == AudioServiceRepeatMode.none
                          ? AudioServiceRepeatMode.all
                          : repeatMode == AudioServiceRepeatMode.all
                              ? AudioServiceRepeatMode.one
                              : AudioServiceRepeatMode.none;
                      _audioHandler.setRepeatMode(nextMode);
                    },
                    icon: Icon(
                      repeatMode == AudioServiceRepeatMode.one
                          ? Icons.repeat_one
                          : Icons.repeat,
                      color: repeatMode != AudioServiceRepeatMode.none
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                  );
                },
              ),
            ],
          ),
          
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildPlayPauseIcon(
    bool isPlaying, 
    AudioProcessingState? processingState, {
    Color? color,
    double? size,
  }) {
    if (processingState == AudioProcessingState.loading ||
        processingState == AudioProcessingState.buffering) {
      return SizedBox(
        width: size ?? 24,
        height: size ?? 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
      );
    }
    
    return Icon(
      isPlaying ? Icons.pause : Icons.play_arrow,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      size: size ?? 24,
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  Stream<PositionData> _getPositionDataStream() {
    return Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
      _audioHandler.playbackState
          .map((state) => state.position)
          .distinct(),
      _audioHandler.playbackState
          .map((state) => state.bufferedPosition)
          .distinct(),
      _audioHandler.mediaItem
          .map((item) => item?.duration)
          .distinct(),
      (position, bufferedPosition, duration) => PositionData(
        position,
        bufferedPosition,
        duration ?? Duration.zero,
      ),
    );
  }
}
