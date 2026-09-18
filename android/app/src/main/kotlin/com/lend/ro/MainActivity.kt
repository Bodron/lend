package com.lend.ro

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    private val downloadsChannel = "lend/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "savePdfToDownloads" -> {
                        try {
                            val name = sanitizeFileName(call.argument<String>("name"))
                            val bytes = call.argument<ByteArray>("bytes")
                                ?: throw IllegalArgumentException("bytes is required")
                            result.success(savePdfToDownloads(name, bytes))
                        } catch (error: Exception) {
                            result.error("SAVE_FAILED", error.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun savePdfToDownloads(name: String, bytes: ByteArray): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, name)
                put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val resolver = applicationContext.contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("Downloads folder is unavailable")

            resolver.openOutputStream(uri)?.use { output ->
                output.write(bytes)
            } ?: throw IllegalStateException("Cannot open Downloads output stream")

            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return uri.toString()
        }

        val downloadsDir = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS
        )
        if (!downloadsDir.exists()) {
            downloadsDir.mkdirs()
        }
        val file = safeChild(downloadsDir, name)
        file.writeBytes(bytes)
        return file.absolutePath
    }

    private fun safeChild(parent: File, fileName: String): File {
        val file = File(parent, fileName)
        val parentPath = parent.canonicalPath + File.separator
        if (!file.canonicalPath.startsWith(parentPath)) {
            throw SecurityException("Invalid file name")
        }
        return file
    }

    private fun sanitizeFileName(fileName: String?): String {
        val safeName = File(fileName ?: "contract.pdf").name
            .replace(Regex("[\\\\/:*?\"<>|\\p{Cntrl}]"), "_")
            .trim()
        return if (safeName.isBlank() || safeName == "." || safeName == "..") {
            "contract.pdf"
        } else {
            safeName
        }
    }
}
