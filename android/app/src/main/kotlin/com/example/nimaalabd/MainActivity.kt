package com.example.nimaalabd

import android.content.Intent
import android.provider.AlarmClock
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: AudioServiceActivity() {
    private val CHANNEL = "com.wasariu.app/alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "checkConnection") {
                result.success(true)
            } else if (call.method == "setSystemAlarm") {
                val hour = call.argument<Int>("hour")
                val minutes = call.argument<Int>("minutes")
                val message = call.argument<String>("message")
                val isTimer = call.argument<Boolean>("isTimer") ?: false
                
                if (isTimer) {
                    val durationMinutes = call.argument<Int>("durationMinutes")
                    if (durationMinutes != null) {
                        setTimer(durationMinutes, message)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Duration is null", null)
                    }
                } else if (hour != null && minutes != null) {
                    setAlarm(hour, minutes, message)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENTS", "Hour or minutes are null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun setAlarm(hour: Int, minutes: Int, message: String?) {
        val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
            putExtra(AlarmClock.EXTRA_HOUR, hour)
            putExtra(AlarmClock.EXTRA_MINUTES, minutes)
            if (message != null) {
                putExtra(AlarmClock.EXTRA_MESSAGE, message)
            }
            putExtra(AlarmClock.EXTRA_SKIP_UI, false)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        try {
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun setTimer(durationMinutes: Int, message: String?) {
        val intent = Intent(AlarmClock.ACTION_SET_TIMER).apply {
            putExtra(AlarmClock.EXTRA_LENGTH, durationMinutes * 60)
            if (message != null) {
                putExtra(AlarmClock.EXTRA_MESSAGE, message)
            }
            putExtra(AlarmClock.EXTRA_SKIP_UI, false)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        try {
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
