package com.r0rt1z2.froggy

import android.service.dreams.DreamService
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

class FroggyDreamService : DreamService() {

    private var engine: FlutterEngine? = null
    private var flutterView: FlutterView? = null

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()

        isFullscreen = true
        isInteractive = false
        isScreenBright = true

        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, null)

        val eng = FlutterEngine(applicationContext)
        eng.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "dreamMain")
        )

        SystemStatus.register(eng, this)

        val view = FlutterView(this)
        view.attachToFlutterEngine(eng)
        setContentView(view)

        engine = eng
        flutterView = view
    }

    override fun onDreamingStarted() {
        super.onDreamingStarted()
        engine?.lifecycleChannel?.appIsResumed()
    }

    override fun onDreamingStopped() {
        engine?.lifecycleChannel?.appIsInactive()
        super.onDreamingStopped()
    }

    override fun onDetachedFromWindow() {
        flutterView?.detachFromFlutterEngine()
        engine?.lifecycleChannel?.appIsDetached()
        engine?.destroy()
        flutterView = null
        engine = null
        super.onDetachedFromWindow()
    }
}
