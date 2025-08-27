package com.example.evercrypted

import com.prongbang.screenprotect.AndroidScreenProtector
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    private val screenProtector by lazy { AndroidScreenProtector.newInstance(this) }
    
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        screenProtector.process(hasFocus.not())
    }
}
