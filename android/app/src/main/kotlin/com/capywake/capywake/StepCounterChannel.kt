package com.capywake.capywake

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * The step sensor for Step Quest. Prefers the per-step detector, else the
 * counter, both registered with no batching. Names match `PlatformStepSensor`.
 */
class StepCounterChannel(context: Context) : EventChannel.StreamHandler, SensorEventListener {
    private val sensors = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val detector: Sensor? = sensors.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)
    private val counter: Sensor? = sensors.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
    private var sink: EventChannel.EventSink? = null
    private var counterBaseline: Float? = null

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "capywake/steps").setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> result.success(detector != null || counter != null)
                else -> result.notImplemented()
            }
        }
        EventChannel(messenger, "capywake/steps/events").setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        val sensor = detector ?: counter
        if (sensor == null) {
            events.error("unavailable", "No step sensor", null)
            return
        }
        sink = events
        counterBaseline = null
        val noBatching = 0
        if (!sensors.registerListener(this, sensor, SensorManager.SENSOR_DELAY_FASTEST, noBatching)) {
            sink = null
            events.error("unregistered", "The step sensor refused a listener", null)
            return
        }
        // A counter may stay silent until a run of steps; flushing sets the baseline now.
        if (sensor == counter) sensors.flush(this)
    }

    override fun onCancel(arguments: Any?) = dispose()

    fun dispose() {
        sensors.unregisterListener(this)
        sink = null
    }

    override fun onSensorChanged(event: SensorEvent) {
        val out = sink ?: return
        when (event.sensor.type) {
            Sensor.TYPE_STEP_DETECTOR -> out.success(1)
            Sensor.TYPE_STEP_COUNTER -> {
                // The counter reports steps since boot; its first event is the baseline.
                val total = event.values[0]
                val base = counterBaseline
                if (base == null) {
                    counterBaseline = total
                    return
                }
                val fresh = (total - base).toInt()
                if (fresh > 0) {
                    counterBaseline = base + fresh
                    out.success(fresh)
                }
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}
}
