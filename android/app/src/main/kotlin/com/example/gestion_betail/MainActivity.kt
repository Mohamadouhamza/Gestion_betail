package com.example.gestion_betail

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

/// Canal natif utilisé par fiche_screen.dart (export PDF/Excel) pour
/// enregistrer directement un fichier dans le dossier public
/// "Téléchargements" de l'appareil, visible immédiatement dans le
/// gestionnaire de fichiers — sans passer par le sélecteur de partage.
///
/// - Android 10+ (API 29+, immense majorité des appareils) : écriture via
///   MediaStore.Downloads, sans permission particulière requise (stockage
///   par portée / scoped storage).
/// - Android < 10 : repli sur l'écriture directe dans le dossier public
///   Téléchargements (nécessite la permission WRITE_EXTERNAL_STORAGE,
///   déclarée dans AndroidManifest.xml avec maxSdkVersion=28). Si
///   l'écriture échoue (permission refusée), l'appel natif échoue
///   proprement et le code Dart se rabat automatiquement sur le partage
///   via share_plus.
class MainActivity : FlutterActivity() {
    private val CHANNEL = "gestion_betail/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "saveToDownloads") {
                val fileName = call.argument<String>("fileName")
                val bytes = call.argument<ByteArray>("bytes")
                val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                if (fileName == null || bytes == null) {
                    result.error("ARGS", "fileName/bytes manquants", null)
                    return@setMethodCallHandler
                }
                try {
                    val uri = saveToDownloads(fileName, bytes, mimeType)
                    result.success(uri)
                } catch (e: Exception) {
                    result.error("SAVE_FAILED", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveToDownloads(fileName: String, bytes: ByteArray, mimeType: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            }
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw Exception("Impossible de créer le fichier dans Téléchargements")
            resolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: throw Exception("Impossible d'ouvrir le flux d'écriture")
            return uri.toString()
        } else {
            @Suppress("DEPRECATION")
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!downloadsDir.exists()) downloadsDir.mkdirs()
            val file = File(downloadsDir, fileName)
            FileOutputStream(file).use { it.write(bytes) }
            return file.absolutePath
        }
    }
}
