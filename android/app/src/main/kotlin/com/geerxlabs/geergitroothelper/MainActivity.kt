package com.geerxlabs.geergitroothelper

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.system.Os
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var pendingSaveResult: MethodChannel.Result? = null
    private var pendingSaveSource: String? = null

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_EXPORT) return
        val result = pendingSaveResult
        val source = pendingSaveSource
        pendingSaveResult = null
        pendingSaveSource = null
        if (result == null) return
        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null || source == null) {
            result.success(null) // user cancelled
            return
        }
        try {
            contentResolver.openOutputStream(uri)!!.use { out ->
                File(source).inputStream().use { it.copyTo(out) }
            }
            result.success(uri.toString())
        } catch (e: Exception) {
            result.error("EXPORT_FAILED", e.message, null)
        }
    }

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
                        "abis" to Build.SUPPORTED_ABIS.joinToString(", "),
                        "fingerprint" to Build.FINGERPRINT,
                        "kernelRelease" to Os.uname().release
                    )
                )

                "getFilesDir" -> result.success(filesDir.absolutePath)

                // Where the APK's bundled libmagiskboot.so was extracted.
                // Executing from nativeLibraryDir passes SELinux; app files
                // dir is W^X-blocked (execute_no_trans denied).
                "getNativeLibraryDir" -> result.success(applicationInfo.nativeLibraryDir)

                // Copies [sourcePath] into a user-chosen location via SAF.
                // Returns the content URI, or null when cancelled.
                "exportFile" -> {
                    val source = call.argument<String>("sourcePath")
                    val name = call.argument<String>("displayName") ?: "new-boot.img"
                    if (source == null) {
                        result.error("BAD_ARGS", "sourcePath is required", null)
                    } else {
                        pendingSaveResult = result
                        pendingSaveSource = source
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "application/octet-stream"
                            putExtra(Intent.EXTRA_TITLE, name)
                        }
                        startActivityForResult(intent, REQUEST_EXPORT)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    companion object {
        private const val REQUEST_EXPORT = 0x7001
    }
}

