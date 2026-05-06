package com.yaandu.fintrack

import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
    override fun onPostCreate(savedInstanceState: android.os.Bundle?) {
        super.onPostCreate(savedInstanceState)

        // Enable edge-to-edge with backward-compatible behavior.
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
