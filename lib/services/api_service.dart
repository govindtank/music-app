import 'dart:convert';
import 'dart:math';
import '../models/track_model.dart';
import '../models/section_model.dart';

class ApiService {
  static const String baseUrl = 'https://api.example.com/v1';
  
  // Sample real audio URLs for testing (these are actual working audio files)
  static const List<String> sampleAudioUrls = [
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3',
    'https://sample-music.netlify.app/death%20bed.mp3',
    'https://sample-music.netlify.app/Bad%20Liar.mp3',
    'https://sample-music.netlify.app/Faded.mp3',
    'https://sample-music.netlify.app/Hate%20Me.mp3',
    'https://sample-music.netlify.app/Solo.mp3',
  ];

  static const List<String> sampleImageUrls = [
    'https://picsum.photos/300/300?random=1',
    'https://picsum.photos/300/300?random=2',
    'https://picsum.photos/300/300?random=3',
    'https://picsum.photos/300/300?random=4',
    'https://picsum.photos/300/300?random=5',
    'https://picsum.photos/300/300?random=6',
    'https://picsum.photos/300/300?random=7',
    'https://picsum.photos/300/300?random=8',
    'https://picsum.photos/300/300?random=9',
    'https://picsum.photos/300/300?random=10',
  ];

  // Sample data that matches your existing app structure
  Future<List<SectionModel>> getSections() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    
    return [
      SectionModel(
        id: 'home',
        name: 'Home',
        description: 'Popular tracks and recommendations',
        iconUrl: 'https://example.com/icons/home.png',
        trackCount: 25,
        playlists: await _getPlaylistsForSection('home'),
      ),
      SectionModel(
        id: 'kirtan',
        name: 'Kirtan',
        description: 'Devotional songs and chants',
        iconUrl: 'https://example.com/icons/kirtan.png',
        trackCount: 30,
        playlists: await _getPlaylistsForSection('kirtan'),
      ),
      SectionModel(
        id: 'katha',
        name: 'Katha',
        description: 'Spiritual stories and discourses',
        iconUrl: 'https://example.com/icons/katha.png',
        trackCount: 20,
        playlists: await _getPlaylistsForSection('katha'),
      ),
      SectionModel(
        id: 'audiobook',
        name: 'AudioBook',
        description: 'Complete audiobooks and series',
        iconUrl: 'https://example.com/icons/audiobook.png',
        trackCount: 15,
        playlists: await _getPlaylistsForSection('audiobook'),
      ),
    ];
  }

  Future<List<PlaylistModel>> _getPlaylistsForSection(String sectionId) async {
    switch (sectionId) {
      case 'home':
        return [
          PlaylistModel(
            id: 'home_popular',
            name: 'Popular Now',
            description: 'Most played tracks this week',
            thumbnail: sampleImageUrls[0],
            trackCount: 12,
            sectionId: sectionId,
          ),
          PlaylistModel(
            id: 'home_recommended',
            name: 'Recommended for You',
            description: 'Based on your listening history',
            thumbnail: sampleImageUrls[1],
            trackCount: 8,
            sectionId: sectionId,
          ),
          PlaylistModel(
            id: 'home_recent',
            name: 'Recently Added',
            description: 'Latest additions to our library',
            thumbnail: sampleImageUrls[2],
            trackCount: 5,
            sectionId: sectionId,
          ),
        ];
        
      case 'kirtan':
        return [
          PlaylistModel(
            id: 'kirtan_morning',
            name: 'Morning Prayers',
            description: 'Start your day with devotion',
            thumbnail: sampleImageUrls[3],
            trackCount: 10,
            sectionId: sectionId,
          ),
          PlaylistModel(
            id: 'kirtan_evening',
            name: 'Evening Aarti',
            description: 'Evening devotional songs',
            thumbnail: sampleImageUrls[4],
            trackCount: 8,
            sectionId: sectionId,
          ),
          PlaylistModel(
            id: 'kirtan_festival',
            name: 'Festival Special',
            description: 'Special occasion kirtans',
            thumbnail: sampleImageUrls[5],
            trackCount: 12,
            sectionId: sectionId,
          ),
        ];
        
      case 'katha':
        return [
          PlaylistModel(
            id: 'katha_ramayana',
            name: 'Ramayana Stories',
            description: 'Epic tales from Ramayana',
            thumbnail: sampleImageUrls[6],
            trackCount: 15,
            sectionId: sectionId,
          ),
          PlaylistModel(
            id: 'katha_bhagavat',
            name: 'Bhagavat Katha',
            description: 'Stories from Bhagavatam',
            thumbnail: sampleImageUrls[7],
            trackCount: 10,
            sectionId: sectionId,
          ),
        ];
        
      case 'audiobook':
        return [
          PlaylistModel(
            id: 'audiobook_gita',
            name: 'Bhagavad Gita',
            description: 'Complete Bhagavad Gita with commentary',
            thumbnail: sampleImageUrls[8],
            trackCount: 18,
            sectionId: sectionId,
          ),
          PlaylistModel(
            id: 'audiobook_upanishad',
            name: 'Upanishads',
            description: 'Selected Upanishads with explanations',
            thumbnail: sampleImageUrls[9],
            trackCount: 12,
            sectionId: sectionId,
          ),
        ];
        
      default:
        return [];
    }
  }

  Future<List<TrackModel>> getTracksForSection(String sectionId) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
    
    final playlists = await _getPlaylistsForSection(sectionId);
    List<TrackModel> allTracks = [];
    
    for (final playlist in playlists) {
      final playlistTracks = await getTracksForPlaylist(playlist.id);
      allTracks.addAll(playlistTracks);
    }
    
    return allTracks;
  }

  Future<List<TrackModel>> getTracksForPlaylist(String playlistId) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    
    final Random random = Random();
    
    switch (playlistId) {
      case 'home_popular':
        return _generateTracks([
          'Peaceful Morning', 'Divine Light', 'Sacred Harmony', 'Blessed Melody',
          'Eternal Peace', 'Golden Sunrise', 'Heavenly Voice', 'Pure Devotion',
          'Morning Bliss', 'Sacred Chant', 'Divine Grace', 'Spiritual Joy'
        ], 'Various Artists', 'Popular Collection', playlistId: playlistId);
        
      case 'home_recommended':
        return _generateTracks([
          'Soulful Journey', 'Inner Peace', 'Meditation Flow', 'Calm Waters',
          'Tranquil Mind', 'Serene Moments', 'Mindful Breathing', 'Gentle Waves'
        ], 'Recommended Artists', 'Personal Mix', playlistId: playlistId);
        
      case 'home_recent':
        return _generateTracks([
          'New Dawn', 'Fresh Start', 'Modern Devotion', 'Contemporary Peace',
          'Latest Blessing'
        ], 'New Artists', 'Recent Additions', playlistId: playlistId);
        
      case 'kirtan_morning':
        return _generateTracks([
          'Om Namah Shivaya', 'Gayatri Mantra', 'Maha Mantra', 'Ganesha Sharanam',
          'Shree Krishna Govind', 'Radhe Krishna', 'Sita Ram', 'Jai Ganesh',
          'Hanuman Chalisa', 'Vishnu Sahasranama'
        ], 'Kirtan Artists', 'Morning Prayers', playlistId: playlistId);
        
      case 'kirtan_evening':
        return _generateTracks([
          'Evening Aarti', 'Sunset Prayers', 'Dusk Devotion', 'Twilight Chants',
          'Evening Bliss', 'Sacred Evening', 'Peaceful Dusk', 'Divine Sunset'
        ], 'Evening Artists', 'Evening Devotion', playlistId: playlistId);
        
      case 'kirtan_festival':
        return _generateTracks([
          'Diwali Special', 'Holi Celebration', 'Navratri Songs', 'Dussehra Joy',
          'Janmashtami Bhajan', 'Ram Navami', 'Ganesh Utsav', 'Shivratri Special',
          'Karva Chauth', 'Raksha Bandhan', 'Krishna Janmashtami', 'Diwali Lights'
        ], 'Festival Artists', 'Festival Collection', playlistId: playlistId);
        
      case 'katha_ramayana':
        return _generateTracks([
          'Ram Janma Katha', 'Sita Swayamvar', 'Vanvas Gatha', 'Hanuman Milan',
          'Lanka Vijay', 'Ram Rajya', 'Bharata Bhakti', 'Lakshman Seva',
          'Kevat Prasang', 'Shabri Bhakti', 'Ram Setu', 'Ravan Vadh',
          'Ashwamedha Yajna', 'Luv Kush Katha', 'Ram Avatar'
        ], 'Katha Narrators', 'Ramayana Series', playlistId: playlistId);
        
      case 'katha_bhagavat':
        return _generateTracks([
          'Krishna Janma', 'Govardhan Leela', 'Raas Leela', 'Kaliya Nag',
          'Butter Thief', 'Vrindavan Stories', 'Gopi Geet', 'Dwarka Leela',
          'Mathura Journey', 'Yashoda Maiya'
        ], 'Bhagavat Speakers', 'Bhagavatam Stories', playlistId: playlistId);
        
      case 'audiobook_gita':
        return _generateTracks([
          'Chapter 1: Arjuna Vishada Yoga', 'Chapter 2: Sankhya Yoga',
          'Chapter 3: Karma Yoga', 'Chapter 4: Gyana Karma Sanyasa Yoga',
          'Chapter 5: Karma Sanyasa Yoga', 'Chapter 6: Dhyana Yoga',
          'Chapter 7: Gyaan Vigyan Yoga', 'Chapter 8: Akshara Brahma Yoga',
          'Chapter 9: Raja Vidya Raja Guhya Yoga', 'Chapter 10: Vibhuti Yoga',
          'Chapter 11: Vishwa Rupa Darshana Yoga', 'Chapter 12: Bhakti Yoga',
          'Chapter 13: Kshetra Kshetrajna Vibhaga Yoga', 'Chapter 14: Gunatraya Vibhaga Yoga',
          'Chapter 15: Purushottama Yoga', 'Chapter 16: Daivasura Sampad Vibhaga Yoga',
          'Chapter 17: Shraddhatraya Vibhaga Yoga', 'Chapter 18: Moksha Sanyasa Yoga'
        ], 'Gita Acharyas', 'Bhagavad Gita', playlistId: playlistId);
        
      case 'audiobook_upanishad':
        return _generateTracks([
          'Isha Upanishad', 'Kena Upanishad', 'Katha Upanishad', 'Prashna Upanishad',
          'Mundaka Upanishad', 'Mandukya Upanishad', 'Taittiriya Upanishad',
          'Aitareya Upanishad', 'Chandogya Upanishad', 'Brihadaranyaka Upanishad',
          'Svetasvatara Upanishad', 'Kaushitaki Upanishad'
        ], 'Upanishad Scholars', 'Upanishad Collection', playlistId: playlistId);
        
      default:
        return [];
    }
  }

  List<TrackModel> _generateTracks(List<String> titles, String artist, String album, {String? playlistId}) {
    final Random random = Random();
    final String actualPlaylistId = playlistId ?? 'unknown_playlist';
    
    return titles.asMap().entries.map((entry) {
      final index = entry.key;
      final title = entry.value;
      
      return TrackModel(
        id: 'track_${actualPlaylistId}_$index',
        title: title,
        artist: artist,
        album: album,
        duration: 180 + random.nextInt(240), // 3-7 minutes
        mediaUrl: sampleAudioUrls[index % sampleAudioUrls.length],
        thumbnail: sampleImageUrls[index % sampleImageUrls.length],
        isFavorite: random.nextBool(),
        isDownloaded: random.nextBool(),
        playCount: random.nextInt(100),
        dateAdded: DateTime.now().subtract(Duration(days: random.nextInt(30))),
        lastPlayed: DateTime.now().subtract(Duration(hours: random.nextInt(24))),
        extras: {
          'genre': _getGenreForPlaylist(actualPlaylistId),
          'language': 'English',
          'quality': 'High',
        },
      );
    }).toList();
  }

  String _getGenreForPlaylist(String playlistId) {
    if (playlistId.contains('kirtan')) return 'Devotional';
    if (playlistId.contains('katha')) return 'Spiritual Story';
    if (playlistId.contains('audiobook')) return 'Educational';
    return 'Spiritual';
  }

  // Search functionality
  Future<List<TrackModel>> searchTracks(String query) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final allSections = await getSections();
    List<TrackModel> allTracks = [];
    
    for (final section in allSections) {
      final sectionTracks = await getTracksForSection(section.id);
      allTracks.addAll(sectionTracks);
    }
    
    final lowercaseQuery = query.toLowerCase();
    return allTracks.where((track) {
      return track.title.toLowerCase().contains(lowercaseQuery) ||
          (track.artist?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (track.album?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  // Favorites management
  Future<bool> toggleFavorite(String trackId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // In a real app, this would call your API
    return true;
  }

  // Download functionality
  Future<bool> downloadTrack(TrackModel track) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate download
    // In a real app, this would download the actual file
    return true;
  }

  // Play tracking
  Future<void> trackPlay(String trackId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Track play statistics
    print('Tracked play for: $trackId');
  }

  // Get actual playable URL (in case you need to transform URLs)
  Future<String> getPlayableUrl(String trackId, String originalUrl) async {
    // In a real app, this might get a signed URL or apply transforms
    return originalUrl;
  }

  // Sync data for Android Auto
  Future<Map<String, dynamic>> getSyncData() async {
    final sections = await getSections();
    List<Map<String, dynamic>> allTracks = [];
    
    for (final section in sections) {
      final tracks = await getTracksForSection(section.id);
      for (final track in tracks) {
        allTracks.add({
          'id': track.id,
          'title': track.title,
          'artist': track.artist,
          'album': track.album,
          'duration': track.duration,
          'mediaUrl': track.mediaUrl,
          'thumbnail': track.thumbnail,
          'sectionId': section.id,
          'sectionName': section.name,
          'playable': true,
          'browsable': false,
        });
      }
    }
    
    return {
      'sections': sections.map((s) => {
        'id': s.id,
        'name': s.name,
        'trackCount': s.trackCount,
        'browsable': true,
        'playable': false,
      }).toList(),
      'tracks': allTracks,
    };
  }
}
