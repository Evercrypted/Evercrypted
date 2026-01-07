package com.example.evercrypted

import com.prongbang.screenprotect.AndroidScreenProtector
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
    private val screenProtector by lazy { AndroidScreenProtector.newInstance(this) }
    
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        screenProtector.process(hasFocus.not())
    }
}
