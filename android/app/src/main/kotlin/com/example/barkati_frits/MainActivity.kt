package com.example.barkati_frits

import android.content.Context
import androidx.multidex.MultiDex
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import android.view.WindowManager.LayoutParams // Import WindowManager.LayoutParams

class MainActivity : FlutterFragmentActivity() {
    override fun attachBaseContext(base: Context?) {
        super.attachBaseContext(base)
        MultiDex.install(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine) // Call super.configureFlutterEngine first
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        // Add this line to prevent screenshots and screen recording for this activity
        window.addFlags(LayoutParams.FLAG_SECURE)
    }
}