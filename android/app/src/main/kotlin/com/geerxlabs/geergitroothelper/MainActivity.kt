package com.geerxlabs.geergitroothelper

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.geerxlabs.geergitroothelper/device_info"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceInfo" -> result.success(
                    mapOf(
                        "model" to Build.MODEL,
                        "manufacturer" to Build.MANUFACTURER,
                        "device" to Build.DEVICE,
                        "androidRelease" to Build.VERSION.RELEASE,
                        "sdkInt" to Build.VERSION.SDK_INT,
                        "abis" to Build.SUPPORTED_ABIS.joinToString(", ")
                    )
                )
                else -> result.notImplemented()
            }
        }
    }
}
