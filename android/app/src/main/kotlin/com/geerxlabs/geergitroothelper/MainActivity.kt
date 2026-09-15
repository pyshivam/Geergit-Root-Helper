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
    private var pendingPickResult: MethodChannel.Result? = null
    private var pendingPickTarget: String? = null

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            REQUEST_EXPORT -> {
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
            REQUEST_PICK -> {
                val result = pendingPickResult
                val target = pendingPickTarget
                pendingPickResult = null
                pendingPickTarget = null
                if (result == null) return
                val uri = data?.data
                if (resultCode != RESULT_OK || uri == null || target == null) {
                    result.success(null) // user cancelled
                    return
                }
                try {
                    // First-party file picking: copy the picked document
                    // straight into the app workspace. file_picker was
                    // replaced after its cache-copy threw unknown_path on
                    // stale DocumentsUI results (picker auto-returning a
                    // phantom URI right after app start).
                    contentResolver.openInputStream(uri)!!.use { input ->
                        File(target).outputStream().use { input.copyTo(it) }
                    }
                    result.success(target)
                } catch (e: Exception) {
                    // Stale/phantom pick result the provider can no longer
                    // open — treat as a failed pick, never a crash.
                    result.error("PICK_FAILED", e.message, null)
                }
            }
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

                // Opens the system document picker and copies the picked
                // document to [targetPath] inside the app workspace.
                // Returns targetPath, null when cancelled, or PICK_FAILED
                // when the returned URI can no longer be opened.
                "pickFile" -> {
                    val target = call.argument<String>("targetPath")
                    if (target == null) {
                        result.error("BAD_ARGS", "targetPath is required", null)
                    } else {
                        pendingPickResult = result
                        pendingPickTarget = target
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "*/*"
                        }
                        startActivityForResult(intent, REQUEST_PICK)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    companion object {
        private const val REQUEST_EXPORT = 0x7001
        private const val REQUEST_PICK = 0x7002
    }
}

