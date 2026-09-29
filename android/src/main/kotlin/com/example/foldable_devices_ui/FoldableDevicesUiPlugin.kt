package com.example.foldable_devices_ui

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel

class FoldableDevicesUiPlugin : FlutterPlugin, EventChannel.StreamHandler {
  private lateinit var eventChannel: EventChannel
  private var sensorManager: SensorManager? = null
  private var hingeAngleSensor: Sensor? = null
  private var sensorListener: SensorEventListener? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    eventChannel = EventChannel(binding.binaryMessenger, "foldable_devices_ui/angle")
    eventChannel.setStreamHandler(this)

    sensorManager = binding.applicationContext.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
    hingeAngleSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_HINGE_ANGLE)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    sensorListener?.let { listener ->
      sensorManager?.unregisterListener(listener)
    }
    sensorListener = null
    hingeAngleSensor = null
    sensorManager = null
    eventChannel.setStreamHandler(null)
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    if (hingeAngleSensor == null) {
      events?.success(0.0)
      return
    }

    sensorListener = object : SensorEventListener {
      override fun onSensorChanged(event: SensorEvent?) {
        event?.values?.firstOrNull()?.let { angle ->
          events?.success(angle.toDouble())
        }
      }

      override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
    }

    sensorListener?.let { listener ->
      sensorManager?.registerListener(
        listener,
        hingeAngleSensor,
        SensorManager.SENSOR_DELAY_NORMAL
      )
    }
  }

  override fun onCancel(arguments: Any?) {
    sensorListener?.let { listener ->
      sensorManager?.unregisterListener(listener)
    }
    sensorListener = null
  }
}
