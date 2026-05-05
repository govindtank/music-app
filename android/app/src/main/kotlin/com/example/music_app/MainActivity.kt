package com.example.music_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    
    private lateinit var androidAutoBridge: AndroidAutoBridge
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize Android Auto bridge
        androidAutoBridge = AndroidAutoBridge(flutterEngine)
    }
}
