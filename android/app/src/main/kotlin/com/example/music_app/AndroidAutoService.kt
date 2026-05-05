package com.example.music_app

import android.os.Bundle
import androidx.media.MediaBrowserServiceCompat
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.MediaDescriptionCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat

class AndroidAutoService : MediaBrowserServiceCompat() {
    
    private lateinit var mediaSession: MediaSessionCompat
    
    companion object {
        private const val MEDIA_ROOT_ID = "root"
        private const val PANELS_ROOT = "panels"
        private const val ALBUMS_ROOT = "albums"
        private const val TRACKS_ROOT = "tracks"
    }
    
    override fun onCreate() {
        super.onCreate()
        
        // Initialize media session
        mediaSession = MediaSessionCompat(this, "AndroidAutoService")
        mediaSession.setFlags(
            MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS or
            MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS
        )
        
        // Set initial playback state
        mediaSession.setPlaybackState(
            PlaybackStateCompat.Builder()
                .setState(PlaybackStateCompat.STATE_NONE, 0, 0f)
                .setActions(
                    PlaybackStateCompat.ACTION_PLAY or
                    PlaybackStateCompat.ACTION_PAUSE or
                    PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
                    PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS
                )
                .build()
        )
        
        sessionToken = mediaSession.sessionToken
    }
    
    override fun onGetRoot(
        clientPackageName: String,
        clientUid: Int,
        rootHints: Bundle?
    ): BrowserRoot? {
        return BrowserRoot(MEDIA_ROOT_ID, null)
    }
    
    override fun onLoadChildren(
        parentId: String,
        result: Result<MutableList<MediaBrowserCompat.MediaItem>>
    ) {
        val mediaItems = mutableListOf<MediaBrowserCompat.MediaItem>()
        
        when (parentId) {
            MEDIA_ROOT_ID -> {
                // Main menu
                mediaItems.add(createBrowsableMediaItem(PANELS_ROOT, "Panels", "Browse by panels"))
                mediaItems.add(createBrowsableMediaItem(ALBUMS_ROOT, "Albums", "Browse by albums"))
                mediaItems.add(createBrowsableMediaItem(TRACKS_ROOT, "All Tracks", "All available tracks"))
            }
            
            PANELS_ROOT -> {
                // Sample panels - in real app, fetch from Flutter data
                mediaItems.add(createBrowsableMediaItem("panel_1", "Islamic Panel", "Islamic music collection"))
                mediaItems.add(createBrowsableMediaItem("panel_2", "Classical Panel", "Classical music collection"))
            }
            
            ALBUMS_ROOT -> {
                // Sample albums - in real app, fetch from Flutter data
                mediaItems.add(createBrowsableMediaItem("album_1", "Beautiful Quran Recitations", "Various Artists"))
                mediaItems.add(createBrowsableMediaItem("album_2", "Peaceful Nasheed", "Ahmed Ali"))
            }
            
            TRACKS_ROOT -> {
                // Sample tracks - in real app, fetch from Flutter data
                mediaItems.add(createPlayableMediaItem("track_1", "Al-Fatiha", "Mishary Rashid", "http://example.com/track1.mp3"))
                mediaItems.add(createPlayableMediaItem("track_2", "Ayat Al-Kursi", "Abdul Rahman Al-Sudais", "http://example.com/track2.mp3"))
            }
        }
        
        result.sendResult(mediaItems)
    }
    
    private fun createBrowsableMediaItem(
        mediaId: String,
        title: String,
        subtitle: String
    ): MediaBrowserCompat.MediaItem {
        val description = MediaDescriptionCompat.Builder()
            .setMediaId(mediaId)
            .setTitle(title)
            .setSubtitle(subtitle)
            .build()
        
        return MediaBrowserCompat.MediaItem(description, MediaBrowserCompat.MediaItem.FLAG_BROWSABLE)
    }
    
    private fun createPlayableMediaItem(
        mediaId: String,
        title: String,
        artist: String,
        mediaUri: String
    ): MediaBrowserCompat.MediaItem {
        val description = MediaDescriptionCompat.Builder()
            .setMediaId(mediaId)
            .setTitle(title)
            .setSubtitle(artist)
            .setMediaUri(android.net.Uri.parse(mediaUri))
            .build()
        
        return MediaBrowserCompat.MediaItem(description, MediaBrowserCompat.MediaItem.FLAG_PLAYABLE)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        mediaSession.release()
    }
}
