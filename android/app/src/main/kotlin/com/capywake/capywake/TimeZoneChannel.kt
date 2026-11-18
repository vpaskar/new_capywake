package com.capywake.capywake

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

/** The device's IANA zone and its change notice. Names match `PlatformZoneChannel`. */
class TimeZoneChannel(private val context: Context) : EventChannel.StreamHandler {
    private var receiver: BroadcastReceiver? = null

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "capywake/timezone").setMethodCallHandler { call, result ->
            when (call.method) {
                "name" -> result.success(TimeZone.getDefault().id)
                else -> result.notImplemented()
            }
        }
        EventChannel(messenger, "capywake/timezone/events").setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        dispose()
        val changed = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                // The default zone may update after this broadcast; the extra is the new one.
                events.success(intent.getStringExtra("time-zone") ?: TimeZone.getDefault().id)
            }
        }
        val filter = IntentFilter(Intent.ACTION_TIMEZONE_CHANGED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(changed, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(changed, filter)
        }
        receiver = changed
    }

    override fun onCancel(arguments: Any?) = dispose()

    fun dispose() {
        receiver?.let { context.unregisterReceiver(it) }
        receiver = null
    }
}
