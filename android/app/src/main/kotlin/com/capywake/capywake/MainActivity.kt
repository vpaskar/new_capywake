package com.capywake.capywake

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var steps: StepCounterChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        steps = StepCounterChannel(applicationContext).also {
            it.register(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        steps?.dispose()
        steps = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
