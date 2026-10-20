package com.example.gestion_betail

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

/// Canal natif utilisé par fiche_screen.dart (export PDF/Excel) pour
/// enregistrer directement un fichier dans le dossier public
/// "Téléchargements" de l'appareil, visible immédiatement dans le
/// gestionnaire de fichiers — sans passer par le sélecteur de partage.
///
/// - Android 10+ (API 29+) : écriture via MediaStore.Downloads, sans
///   permission particulière (scoped storage). Le fichier est d'abord créé
///   avec IS_PENDING = 1 (invisible, en cours d'écriture), rempli, puis
///   publié avec IS_PENDING = 0 : c'est la séquence recommandée par Android ;
///   sans elle, certains appareils/versions (Android 11+) n'indexent pas
///   correctement le fichier. Si l'écriture échoue, l'entrée orpheline est
///   supprimée.
/// - Android < 10 : écriture directe dans le dossier public Téléchargements
///   (permission WRITE_EXTERNAL_STORAGE, maxSdkVersion=28 dans le manifeste).
///
/// En cas d'échec, l'erreur renvoyée à Dart contient le NOM de l'exception
/// et son message, affichés tels quels dans l'application pour diagnostic.
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
                    result.success(saveToDownloads(fileName, bytes, mimeType))
                } catch (t: Throwable) {
                    result.error(
                        "SAVE_FAILED",
                        "${t.javaClass.simpleName}: ${t.message}",
                        "SDK ${Build.VERSION.SDK_INT} / ${Build.MANUFACTURER} ${Build.MODEL}"
                    )
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveToDownloads(fileName: String, bytes: ByteArray, mimeType: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return saveWithMediaStore(fileName, bytes, mimeType)
        }
        return saveLegacy(fileName, bytes)
    }

    @android.annotation.TargetApi(Build.VERSION_CODES.Q)
    private fun saveWithMediaStore(fileName: String, bytes: ByteArray, mimeType: String): String {
        val resolver = applicationContext.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
        val uri: Uri = resolver.insert(collection, values)
            ?: throw IllegalStateException("MediaStore.insert a renvoyé null (impossible de créer l'entrée dans Téléchargements)")
        try {
            val stream = resolver.openOutputStream(uri, "w")
                ?: throw IllegalStateException("openOutputStream a renvoyé null pour $uri")
            stream.use {
                it.write(bytes)
                it.flush()
            }
            val publie = ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }
            resolver.update(uri, publie, null, null)
        } catch (t: Throwable) {
            // Ne laisse pas d'entrée orpheline (fichier vide/invisible).
            try {
                resolver.delete(uri, null, null)
            } catch (_: Throwable) {
            }
            throw t
        }
        return uri.toString()
    }

    private fun saveLegacy(fileName: String, bytes: ByteArray): String {
        @Suppress("DEPRECATION")
        val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (!downloadsDir.exists()) downloadsDir.mkdirs()
        val file = File(downloadsDir, fileName)
        FileOutputStream(file).use { it.write(bytes) }
        return file.absolutePath
    }
}
