import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_service/audio_service.dart';
import '../models/track_model.dart';
import '../models/section_model.dart';
import '../models/playlist_model.dart';
import '../services/audio_service.dart';
import '../bloc/track_list_bloc.dart';
import '../widgets/miniplayer.dart';

class EnhancedTrackList extends StatefulWidget {
  final String? initialSectionId;
  final String? initialPlaylistId;
  
  const EnhancedTrackList({
    Key? key,
    this.initialSectionId,
    this.initialPlaylistId,
  }) : super(key: key);

  @override
  State<EnhancedTrackList> createState() => _EnhancedTrackListState();
}

class _EnhancedTrackListState extends State<EnhancedTrackList>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TrackListBloc _trackListBloc;
  late AudioHandler _audioHandler;
  
  String? selectedSectionId;
  String? selectedPanelId;
  String? selectedPlaylistId;
  
  List<SectionModel> sections = [];
  List<TrackModel> currentTracks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _audioHandler = GetIt.instance<AudioHandler>();
    _trackListBloc = TrackListBloc();
    
    // Initialize with default sections or provided section
    selectedSectionId = widget.initialSectionId;
    selectedPlaylistId = widget.initialPlaylistId;
    
    _loadInitialData();
  }

  void _loadInitialData() async {
    setState(() => isLoading = true);
    
    try {
      // Load sections (Home, Kirtan, Katha, AudioBook)
      sections = await _trackListBloc.loadSections();
      
      if (sections.isNotEmpty) {
        // Initialize tab controller with sections
        _tabController = TabController(
          length: sections.length,
          vsync: this,
        );
        
        // Set initial section if not provided
        if (selectedSectionId == null) {
          selectedSectionId = sections.first.id;
        }
        
        // Find initial tab index
        int initialIndex = sections.indexWhere((s) => s.id == selectedSectionId);
        if (initialIndex >= 0) {
          _tabController.index = initialIndex;
        }
        
        // Load initial section data
        await _loadSectionData(selectedSectionId!);
        
        _tabController.addListener(_onTabChanged);
      }
    } catch (e) {
      print('Error loading initial data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    
    final newSectionId = sections[_tabController.index].id;
    if (newSectionId != selectedSectionId) {
      selectedSectionId = newSectionId;
      selectedPanelId = null;
      selectedPlaylistId = null;
      _loadSectionData(newSectionId);
    }
  }

  Future<void> _loadSectionData(String sectionId) async {
    setState(() => isLoading = true);
    
    try {
      currentTracks = await _trackListBloc.loadTracksForSection(sectionId);
    } catch (e) {
      print('Error loading section data: $e');
      currentTracks = [];
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadPlaylistTracks(String playlistId) async {
    setState(() => isLoading = true);
    
    try {
      currentTracks = await _trackListBloc.loadTracksForPlaylist(playlistId);
      selectedPlaylistId = playlistId;
    } catch (e) {
      print('Error loading playlist tracks: $e');
      currentTracks = [];
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _trackListBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          // Section Tabs
          if (sections.isNotEmpty)
            Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 2,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Theme.of(context).primaryColor,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
                tabs: sections.map((section) => Tab(
                  text: section.name,
                  icon: _getSectionIcon(section.name),
                )).toList(),
              ),
            ),
          
          // Content Area
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(),
          ),
          
          // Mini Player
          const MiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (currentTracks.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      slivers: [
        // Section Header
        SliverToBoxAdapter(
          child: _buildSectionHeader(),
        ),
        
        // Filters and Search
        SliverToBoxAdapter(
          child: _buildFiltersRow(),
        ),
        
        // Track List
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildTrackItem(currentTracks[index], index),
            childCount: currentTracks.length,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    final currentSection = sections.firstWhere((s) => s.id == selectedSectionId);
    
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentSection.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            '${currentTracks.length} tracks available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Container(
      height: 6.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          // Search Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showSearchDialog,
              icon: const Icon(Icons.search, size: 20),
              label: const Text('Search tracks...'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 4.w),
              ),
            ),
          ),
          SizedBox(width: 2.w),
          
          // Filter Button
          OutlinedButton.icon(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list, size: 20),
            label: const Text('Filter'),
          ),
          
          SizedBox(width: 2.w),
          
          // Sort Button
          OutlinedButton.icon(
            onPressed: _showSortDialog,
            icon: const Icon(Icons.sort, size: 20),
            label: const Text('Sort'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackItem(TrackModel track, int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(2.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(3.w),
        leading: Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2.w),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2.w),
            child: track.thumbnail != null
              ? CachedNetworkImage(
                  imageUrl: track.thumbnail!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.music_note),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.music_note),
                  ),
                )
              : Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.music_note),
                ),
          ),
        ),
        title: Text(
          track.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 0.5.h),
            Text(
              track.artist ?? 'Unknown Artist',
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 0.5.h),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 1.w),
                Text(
                  _formatDuration(track.duration ?? 0),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (track.isFavorite)
                  Icon(
                    Icons.favorite,
                    size: 16,
                    color: Colors.red,
                  ),
                if (track.isDownloaded)
                  Padding(
                    padding: EdgeInsets.only(left: 2.w),
                    child: Icon(
                      Icons.download_done,
                      size: 16,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleTrackAction(value, track),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'play_next',
              child: Text('Play Next'),
            ),
            const PopupMenuItem(
              value: 'add_to_queue',
              child: Text('Add to Queue'),
            ),
            const PopupMenuItem(
              value: 'add_to_playlist',
              child: Text('Add to Playlist'),
            ),
            PopupMenuItem(
              value: track.isFavorite ? 'remove_favorite' : 'add_favorite',
              child: Text(track.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
            ),
            if (!track.isDownloaded)
              const PopupMenuItem(
                value: 'download',
                child: Text('Download'),
              ),
            const PopupMenuItem(
              value: 'share',
              child: Text('Share'),
            ),
          ],
        ),
        onTap: () => _playTrack(track, index),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 20.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 2.h),
          Text(
            'No tracks available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Try selecting a different section or refresh',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Icon _getSectionIcon(String sectionName) {
    switch (sectionName.toLowerCase()) {
      case 'home':
        return const Icon(Icons.home, size: 20);
      case 'kirtan':
        return const Icon(Icons.library_music, size: 20);
      case 'katha':
        return const Icon(Icons.record_voice_over, size: 20);
      case 'audiobook':
        return const Icon(Icons.book, size: 20);
      default:
        return const Icon(Icons.music_note, size: 20);
    }
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(secs)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(secs)}';
  }

  void _playTrack(TrackModel track, int index) async {
    try {
      // Create media item
      final mediaItem = MediaItem(
        id: track.mediaUrl,
        album: track.album,
        title: track.title,
        artist: track.artist,
        duration: Duration(seconds: track.duration ?? 0),
        artUri: track.thumbnail != null ? Uri.parse(track.thumbnail!) : null,
        extras: {
          'trackId': track.id,
          'playlistId': selectedPlaylistId,
          'index': index,
        },
      );

      // Update queue and play
      await _audioHandler.updateQueue(
        currentTracks.map((t) => MediaItem(
          id: t.mediaUrl,
          album: t.album,
          title: t.title,
          artist: t.artist,
          duration: Duration(seconds: t.duration ?? 0),
          artUri: t.thumbnail != null ? Uri.parse(t.thumbnail!) : null,
          extras: {
            'trackId': t.id,
            'playlistId': selectedPlaylistId,
          },
        )).toList(),
      );

      await _audioHandler.skipToQueueItem(index);
      await _audioHandler.play();

      // Analytics
      _trackAnalytics('track_played', track);

    } catch (e) {
      print('Error playing track: $e');
      _showErrorSnackbar('Failed to play track');
    }
  }

  void _handleTrackAction(String action, TrackModel track) async {
    switch (action) {
      case 'play_next':
        await _addTrackToQueue(track, playNext: true);
        break;
      case 'add_to_queue':
        await _addTrackToQueue(track);
        break;
      case 'add_to_playlist':
        _showAddToPlaylistDialog(track);
        break;
      case 'add_favorite':
      case 'remove_favorite':
        await _toggleFavorite(track);
        break;
      case 'download':
        await _downloadTrack(track);
        break;
      case 'share':
        _shareTrack(track);
        break;
    }
  }

  Future<void> _addTrackToQueue(TrackModel track, {bool playNext = false}) async {
    try {
      final mediaItem = MediaItem(
        id: track.mediaUrl,
        album: track.album,
        title: track.title,
        artist: track.artist,
        duration: Duration(seconds: track.duration ?? 0),
        artUri: track.thumbnail != null ? Uri.parse(track.thumbnail!) : null,
      );

      if (playNext) {
        final currentIndex = _audioHandler.queue.value.isEmpty ? 0 : 1;
        await _audioHandler.insertQueueItem(currentIndex, mediaItem);
        _showSnackbar('Track added to play next');
      } else {
        await _audioHandler.addQueueItem(mediaItem);
        _showSnackbar('Track added to queue');
      }
    } catch (e) {
      print('Error adding track to queue: $e');
      _showErrorSnackbar('Failed to add track to queue');
    }
  }

  Future<void> _toggleFavorite(TrackModel track) async {
    try {
      await _trackListBloc.toggleFavorite(track.id);
      setState(() {
        track.isFavorite = !track.isFavorite;
      });
      _showSnackbar(track.isFavorite ? 'Added to favorites' : 'Removed from favorites');
    } catch (e) {
      print('Error toggling favorite: $e');
      _showErrorSnackbar('Failed to update favorites');
    }
  }

  Future<void> _downloadTrack(TrackModel track) async {
    try {
      _showSnackbar('Download started...');
      await _trackListBloc.downloadTrack(track);
      setState(() {
        track.isDownloaded = true;
      });
      _showSnackbar('Track downloaded successfully');
    } catch (e) {
      print('Error downloading track: $e');
      _showErrorSnackbar('Failed to download track');
    }
  }

  void _shareTrack(TrackModel track) {
    // TODO: Implement share functionality
    _showSnackbar('Share functionality coming soon');
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Tracks'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter track name...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (query) {
            Navigator.pop(context);
            _performSearch(query);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    // TODO: Implement filter dialog
    _showSnackbar('Filter options coming soon');
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Name (A-Z)'),
              onTap: () {
                Navigator.pop(context);
                _sortTracks('name_asc');
              },
            ),
            ListTile(
              title: const Text('Name (Z-A)'),
              onTap: () {
                Navigator.pop(context);
                _sortTracks('name_desc');
              },
            ),
            ListTile(
              title: const Text('Duration (Short to Long)'),
              onTap: () {
                Navigator.pop(context);
                _sortTracks('duration_asc');
              },
            ),
            ListTile(
              title: const Text('Duration (Long to Short)'),
              onTap: () {
                Navigator.pop(context);
                _sortTracks('duration_desc');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(TrackModel track) {
    // TODO: Implement add to playlist dialog
    _showSnackbar('Add to playlist feature coming soon');
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() => isLoading = true);
    try {
      currentTracks = await _trackListBloc.searchTracks(query);
    } catch (e) {
      print('Error searching tracks: $e');
      _showErrorSnackbar('Search failed');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _sortTracks(String sortType) {
    setState(() {
      switch (sortType) {
        case 'name_asc':
          currentTracks.sort((a, b) => a.title.compareTo(b.title));
          break;
        case 'name_desc':
          currentTracks.sort((a, b) => b.title.compareTo(a.title));
          break;
        case 'duration_asc':
          currentTracks.sort((a, b) => (a.duration ?? 0).compareTo(b.duration ?? 0));
          break;
        case 'duration_desc':
          currentTracks.sort((a, b) => (b.duration ?? 0).compareTo(a.duration ?? 0));
          break;
      }
    });
    _showSnackbar('Tracks sorted');
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _trackAnalytics(String event, TrackModel track) {
    // TODO: Implement analytics
    print('Analytics: $event - ${track.title}');
  }
}
