package com.jrq.listah

import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channel = "listah/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveCsv" -> {
                        val name = call.argument<String>("name") ?: run {
                            result.error("ARG", "Missing name", null)
                            return@setMethodCallHandler
                        }
                        val bytes = call.argument<ByteArray>("bytes") ?: run {
                            result.error("ARG", "Missing bytes", null)
                            return@setMethodCallHandler
                        }

                        try {
                            val savedUri = saveCsvToDownloads(name, bytes)
                            result.success(savedUri)
                        } catch (e: Exception) {
                            result.error("IO", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun saveCsvToDownloads(fileName: String, data: ByteArray): String {
        val fullName = if (fileName.endsWith(".csv")) fileName else "$fileName.csv"

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fullName)
                put(MediaStore.Downloads.MIME_TYPE, "text/csv")
                put(MediaStore.Downloads.IS_PENDING, 1)
            }

            val resolver = applicationContext.contentResolver
            val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val itemUri: Uri = resolver.insert(collection, values)
                ?: throw IllegalStateException("Failed to create download entry")

            resolver.openOutputStream(itemUri)?.use { os ->
                os.write(data)
                os.flush()
            } ?: throw IllegalStateException("Failed to open output stream")

            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(itemUri, values, null, null)
            itemUri.toString()
        } else {
            // Legacy external storage path
            val downloads = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!downloads.exists()) downloads.mkdirs()
            val outFile = File(downloads, fullName)
            FileOutputStream(outFile).use { it.write(data) }
            outFile.absolutePath
        }
    }
}
