import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/track_model.dart';
import '../models/section_model.dart';
import '../models/playlist_model.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

// Events
abstract class TrackListEvent {}

class LoadSections extends TrackListEvent {}

class LoadTracksForSection extends TrackListEvent {
  final String sectionId;
  LoadTracksForSection(this.sectionId);
}

class LoadTracksForPlaylist extends TrackListEvent {
  final String playlistId;
  LoadTracksForPlaylist(this.playlistId);
}

class SearchTracks extends TrackListEvent {
  final String query;
  SearchTracks(this.query);
}

class FilterTracks extends TrackListEvent {
  final TrackFilter filter;
  FilterTracks(this.filter);
}

class SortTracks extends TrackListEvent {
  final TrackSortType sortType;
  final bool ascending;
  SortTracks(this.sortType, {this.ascending = true});
}

class ToggleFavorite extends TrackListEvent {
  final String trackId;
  ToggleFavorite(this.trackId);
}

class DownloadTrack extends TrackListEvent {
  final TrackModel track;
  DownloadTrack(this.track);
}

class LoadFavorites extends TrackListEvent {}

class LoadRecentlyPlayed extends TrackListEvent {}

class LoadDownloaded extends TrackListEvent {}

class RefreshData extends TrackListEvent {}

// States
abstract class TrackListState {}

class TrackListInitial extends TrackListState {}

class TrackListLoading extends TrackListState {}

class TrackListLoaded extends TrackListState {
  final List<TrackModel> tracks;
  final List<SectionModel> sections;
  final TrackFilter? currentFilter;
  final TrackSortType currentSort;
  final bool sortAscending;
  final String? searchQuery;

  TrackListLoaded({
    required this.tracks,
    required this.sections,
    this.currentFilter,
    this.currentSort = TrackSortType.name,
    this.sortAscending = true,
    this.searchQuery,
  });

  TrackListLoaded copyWith({
    List<TrackModel>? tracks,
    List<SectionModel>? sections,
    TrackFilter? currentFilter,
    TrackSortType? currentSort,
    bool? sortAscending,
    String? searchQuery,
  }) {
    return TrackListLoaded(
      tracks: tracks ?? this.tracks,
      sections: sections ?? this.sections,
      currentFilter: currentFilter ?? this.currentFilter,
      currentSort: currentSort ?? this.currentSort,
      sortAscending: sortAscending ?? this.sortAscending,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class TrackListError extends TrackListState {
  final String message;
  TrackListError(this.message);
}

class FavoriteToggled extends TrackListState {
  final String trackId;
  final bool isFavorite;
  FavoriteToggled(this.trackId, this.isFavorite);
}

class TrackDownloadStarted extends TrackListState {
  final String trackId;
  TrackDownloadStarted(this.trackId);
}

class TrackDownloadCompleted extends TrackListState {
  final String trackId;
  TrackDownloadCompleted(this.trackId);
}

class TrackDownloadFailed extends TrackListState {
  final String trackId;
  final String error;
  TrackDownloadFailed(this.trackId, this.error);
}

// Filter and Sort Types
enum TrackSortType {
  name,
  artist,
  album,
  duration,
  dateAdded,
  playCount,
}

class TrackFilter {
  final String? artist;
  final String? album;
  final String? genre;
  final bool? isFavorite;
  final bool? isDownloaded;
  final Duration? minDuration;
  final Duration? maxDuration;

  const TrackFilter({
    this.artist,
    this.album,
    this.genre,
    this.isFavorite,
    this.isDownloaded,
    this.minDuration,
    this.maxDuration,
  });

  bool isEmpty() {
    return artist == null &&
        album == null &&
        genre == null &&
        isFavorite == null &&
        isDownloaded == null &&
        minDuration == null &&
        maxDuration == null;
  }
}

// BLoC Implementation
class TrackListBloc extends Bloc<TrackListEvent, TrackListState> {
  final ApiService _apiService;
  final DatabaseService _databaseService;
  
  List<TrackModel> _allTracks = [];
  List<SectionModel> _sections = [];

  TrackListBloc({
    required ApiService apiService,
    required DatabaseService databaseService,
  })  : _apiService = apiService,
        _databaseService = databaseService,
        super(TrackListInitial()) {
    
    on<LoadSections>(_onLoadSections);
    on<LoadTracksForSection>(_onLoadTracksForSection);
    on<LoadTracksForPlaylist>(_onLoadTracksForPlaylist);
    on<SearchTracks>(_onSearchTracks);
    on<FilterTracks>(_onFilterTracks);
    on<SortTracks>(_onSortTracks);
    on<ToggleFavorite>(_onToggleFavorite);
    on<DownloadTrack>(_onDownloadTrack);
    on<LoadFavorites>(_onLoadFavorites);
    on<LoadRecentlyPlayed>(_onLoadRecentlyPlayed);
    on<LoadDownloaded>(_onLoadDownloaded);
    on<RefreshData>(_onRefreshData);
  }

  Future<void> _onLoadSections(
    LoadSections event,
    Emitter<TrackListState> emit,
  ) async {
    try {
      emit(TrackListLoading());
      
      _sections = await _apiService.getSections();
      
      emit(TrackListLoaded(
        tracks: [],
        sections: _sections,
      ));
      
    } catch (e) {
      emit(TrackListError('Failed to load sections: $e'));
    }
  }

  Future<void> _onLoadTracksForSection(
    LoadTracksForSection event,
    Emitter<TrackListState> emit,
  ) async {
    try {
      emit(TrackListLoading());
      
      final tracks = await _apiService.getTracksForSection(event.sectionId);
      _allTracks = tracks;
      
      // Load from database for offline data
      final offlineTracks = await _databaseService.getTracksForSection(event.sectionId);
      
      // Merge online and offline data
      final mergedTracks = _mergeTracks(tracks, offlineTracks);
      
      emit(TrackListLoaded(
        tracks: mergedTracks,
        sections: _sections,
      ));
      
    } catch (e) {
      // Fallback to offline data
      try {
        final offlineTracks = await _databaseService.getTracksForSection(event.sectionId);
        emit(TrackListLoaded(
          tracks: offlineTracks,
          sections: _sections,
        ));
      } catch (offlineError) {
        emit(TrackListError('Failed to load tracks: $e'));
      }
    }
  }

  Future<void> _onLoadTracksForPlaylist(
    LoadTracksForPlaylist event,
    Emitter<TrackListState> emit,
  ) async {
    try {
      emit(TrackListLoading());
      
      final tracks = await _apiService.getTracksForPlaylist(event.playlistId);
      _allTracks = tracks;
      
      // Load from database for offline data
      final offlineTracks = await _databaseService.getTracksForPlaylist(event.playlistId);
      
      // Merge online and offline data
      final mergedTracks = _mergeTracks(tracks, offlineTracks);
      
      emit(TrackListLoaded(
        tracks: mergedTracks,
        sections: _sections,
      ));
      
    } catch (e) {
      // Fallback to offline data
      try {
        final offlineTracks = await _databaseService.getTracksForPlaylist(event.playlistId);
        emit(TrackListLoaded(
          tracks: offlineTracks,
          sections: _sections,
        ));
      } catch (offlineError) {
        emit(TrackListError('Failed to load playlist tracks: $e'));
      }
    }
  }

  Future<void> _onSearchTracks(
    SearchTracks event,
    Emitter<TrackListState> emit,
  ) async {
    try {
      if (state is! TrackListLoaded) return;
      
      final currentState = state as TrackListLoaded;
      
      if (event.query.trim().isEmpty) {
        // Reset to all tracks
        emit(currentState.copyWith(
          tracks: _allTracks,
          searchQuery: null,
        ));
        return;
      }
      
      final query = event.query.toLowerCase().trim();
      final filteredTracks = _allTracks.where((track) {
        return track.title.toLowerCase().contains(query) ||
            (track.artist?.toLowerCase().contains(query) ?? false) ||
            (track.album?.toLowerCase().contains(query) ?? false);
      }).toList();
      
      emit(currentState.copyWith(
        tracks: filteredTracks,
        searchQuery: event.query,
      ));
      
    } catch (e) {
      emit(TrackListError('Search failed: $e'));
    }
  }

  Future<void> _onFilterTracks(
    FilterTracks event,
    Emitter<TrackListState> emit,
  ) async {
    try {
      if (state is! TrackListLoaded) return;
      
      final currentState = state as TrackListLoaded;
      
      List<TrackModel> filteredTracks = List.from(_allTracks);
      
      if (!event.filter.isEmpty()) {
        filteredTracks = filteredTracks.where((track) {
          // Artist filter
          if (event.filter.artist != null) {
            if (track.artist?.toLowerCase() != event.filter.artist!.toLowerCase()) {
              return false;
            }
          }
          
          // Album filter
          if (event.filter.album != null) {
            if (track.album?.toLowerCase() != event.filter.album!.toLowerCase()) {
              return false;
            }
          }
          
          // Favorite filter
          if (event.filter.isFavorite != null) {
            if (track.isFavorite != event.filter.isFavorite!) {
              return false;
            }
          }
          
          // Downloaded filter
          if (event.filter.isDownloaded != null) {
            if (track.isDownloaded != event.filter.isDownloaded!) {
              return false;
            }
          }
          
          // Duration filters
          if (event.filter.minDuration != null && track.duration != null) {
            if (Duration(seconds: track.duration!) < event.filter.minDuration!) {
              return false;
            }
          }
          
          if (event.filter.maxDuration != null && track.duration != null) {
            if (Duration(seconds: track.duration!) > event.filter.maxDuration!) {
              return false;
            }
          }
          
          return true;
        }).toList();
      }
      
      emit(currentState.copyWith(
        tracks: filteredTracks,
        currentFilter: event.filter,
      ));
      
    } catch (e) {
      emit(TrackListError('Filter failed: $e'));
    }
  }

  Future<void> _onSortTracks(
    SortTracks event,
    Emitter<TrackListState> emit,
  ) async {
    try {
      if (state is! TrackListLoaded) return;
      
      final currentState = state as TrackListLoaded;
      final tracks = List<TrackModel>.from(currentState.tracks);
      
      tracks.sort((a, b) {
        int comparison;
        
        switch (event.sortType) {
          case TrackSortType.name:
            comparison = a.title.compareTo(b.title);
            break;
          case TrackSortType.artist:
            comparison = (a.artist ?? '').compareTo(b.artist ?? '');
            break;
          case TrackSortType.album:
            comparison = (a.album ?? '').compareTo(b.album ?? '');
            break;
          case TrackSortType.duration:
            comparison = (a.duration ?? 0).compareTo(b.duration ?? 0);
            break;
          case TrackSortType.dateAdded:
            comparison = (a.dateAdded ?? DateTime.now())
                .compareTo(b.dateAdded ?? DateTime.now());
            break;
          case TrackSortType.playCount:
            comparison = (a.playCount ?? 0).compareTo(b.playCount ?? 0);
            break;
        }
        
        return event.ascending ? comparison : -comparison;
      });
      
      emit(currentState.copyWith(
        tracks: tracks,
        currentSort: event.sortType,
        sortAscending: event.ascending,
      ));
      
    } catch (e) {
      emit(TrackListError('Sort failed: $e'));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<TrackListState> emit,
  ) async {
    try {
      final success = await _apiService.toggleFavorite(event.trackId);
      
      if (success) {
        // Update local data
        await _databaseService.toggleFavorite(event.trackId);
        
        // Update tracks list
        _allTracks = _allTracks.map((track) {
          if (track.id == event.trackId) {
            return track.copyWith(isFavorite: !track.isFavorite);
          }
          return track;
        }).toList();
        
        // Update current state
        if (state is TrackListLoaded) {
          final currentState = state as TrackListLoaded;
          final updatedTracks = currentState.tracks.map((track) {
            if (track.id == event.trackId) {
              return track.copyWith(isFavorite: !track.isFavorite);
            }
            return track;
          }).toList();
          
          emit(currentState.copyWith(tracks: updatedTracks));
        }
        
        emit(FavoriteToggled(event.trackId, true)); // Temp state for UI feedback
        
      } else {
        emit(TrackListError('Failed to toggle favorite'));
      }
      
    } catch (e) {
      emit(TrackListError('Failed to toggle favorite: $e'));
    }
  }

  Future<void> _onDownloadTrack(
    DownloadTrack event,
    Emitter<TrackListState> emit,
  ) async {
    try {
      emit(TrackDownloadStarted(event.track.id));
      
      final success = await _apiService.downloadTrack(event.track);
      
      if (success) {
        // Update local data
        await _databaseService.markAsDownloaded(event.track.id);
        
        // Update tracks list
        _allTracks = _allTracks.map((track) {
          if (track.id == event.track.id) {
            return track.copyWith(isDownloaded: true);
          }
          return track;
        }).toList();
        
        emit(TrackDownloadCompleted(event.track.id));
        
      } else {
        emit(TrackDownloadFailed(event.track.id, 'Download failed'));
      }
      
    } catch (e) {
      emit(TrackDownloadFailed(event.track.id, e.toString()));
    }
  }

  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<TrackListState> emit,
  ) async {
    try {
      emit(TrackListLoading());
      
      final favorites = await _databaseService.getFavoriteTracks();
      _allTracks = favorites;
      
      emit(TrackListLoaded(
        tracks: favorites,
        sections: _sections,
      ));
      
    } catch (e) {
      emit(TrackListError('Failed to load favorites: $e'));
    }
  }

  Future<void> _onLoadRecentlyPlayed(
    LoadRecentlyPlayed event,
    Emitter<TrackListState> emit,
  ) async {
    try {
      emit(TrackListLoading());
      
      final recentTracks = await _databaseService.getRecentlyPlayedTracks();
      _allTracks = recentTracks;
      
      emit(TrackListLoaded(
        tracks: recentTracks,
        sections: _sections,
      ));
      
    } catch (e) {
      emit(TrackListError('Failed to load recently played: $e'));
    }
  }

  Future<void> _onLoadDownloaded(
    LoadDownloaded event,
    Emitter<TrackListState> emit,
  ) async {
    try {
      emit(TrackListLoading());
      
      final downloadedTracks = await _databaseService.getDownloadedTracks();
      _allTracks = downloadedTracks;
      
      emit(TrackListLoaded(
        tracks: downloadedTracks,
        sections: _sections,
      ));
      
    } catch (e) {\n      emit(TrackListError('Failed to load downloaded tracks: $e'));\n    }\n  }\n\n  Future<void> _onRefreshData(\n    RefreshData event,\n    Emitter<TrackListState> emit,\n  ) async {\n    try {\n      // Clear caches\n      _allTracks.clear();\n      \n      // Reload sections\n      _sections = await _apiService.getSections();\n      \n      emit(TrackListLoaded(\n        tracks: [],\n        sections: _sections,\n      ));\n      \n    } catch (e) {\n      emit(TrackListError('Failed to refresh data: $e'));\n    }\n  }\n\n  // Helper method to merge online and offline tracks\n  List<TrackModel> _mergeTracks(List<TrackModel> onlineTracks, List<TrackModel> offlineTracks) {\n    final Map<String, TrackModel> trackMap = {};\n    \n    // Add offline tracks first\n    for (final track in offlineTracks) {\n      trackMap[track.id] = track;\n    }\n    \n    // Override with online data (more up-to-date)\n    for (final track in onlineTracks) {\n      final existing = trackMap[track.id];\n      if (existing != null) {\n        // Merge data, keeping downloaded status from offline\n        trackMap[track.id] = track.copyWith(\n          isDownloaded: existing.isDownloaded,\n          downloadPath: existing.downloadPath,\n        );\n      } else {\n        trackMap[track.id] = track;\n      }\n    }\n    \n    return trackMap.values.toList();\n  }\n\n  // Public convenience methods for the widget to use\n  Future<List<SectionModel>> loadSections() async {\n    try {\n      return await _apiService.getSections();\n    } catch (e) {\n      return await _databaseService.getSections();\n    }\n  }\n\n  Future<List<TrackModel>> loadTracksForSection(String sectionId) async {\n    try {\n      final onlineTracks = await _apiService.getTracksForSection(sectionId);\n      final offlineTracks = await _databaseService.getTracksForSection(sectionId);\n      return _mergeTracks(onlineTracks, offlineTracks);\n    } catch (e) {\n      return await _databaseService.getTracksForSection(sectionId);\n    }\n  }\n\n  Future<List<TrackModel>> loadTracksForPlaylist(String playlistId) async {\n    try {\n      final onlineTracks = await _apiService.getTracksForPlaylist(playlistId);\n      final offlineTracks = await _databaseService.getTracksForPlaylist(playlistId);\n      return _mergeTracks(onlineTracks, offlineTracks);\n    } catch (e) {\n      return await _databaseService.getTracksForPlaylist(playlistId);\n    }\n  }\n\n  Future<List<TrackModel>> searchTracks(String query) async {\n    try {\n      return await _apiService.searchTracks(query);\n    } catch (e) {\n      return await _databaseService.searchTracks(query);\n    }\n  }\n\n  Future<void> toggleFavorite(String trackId) async {\n    await _apiService.toggleFavorite(trackId);\n    await _databaseService.toggleFavorite(trackId);\n  }\n\n  Future<void> downloadTrack(TrackModel track) async {\n    await _apiService.downloadTrack(track);\n    await _databaseService.markAsDownloaded(track.id);\n  }\n}
