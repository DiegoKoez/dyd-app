package com.dyd.dyd_app

import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val channelName = "socket_keep_alive"
    private lateinit var channel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    startSocketKeepAlive()
                    result.success(null)
                }
                "stop" -> {
                    stopSocketKeepAlive()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startSocketKeepAlive() {
        val intent = Intent(this, SocketKeepAliveService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopSocketKeepAlive() {
        stopService(Intent(this, SocketKeepAliveService::class.java))
    }
}
