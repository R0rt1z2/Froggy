package com.r0rt1z2.froggy

import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.view.WindowManager
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val APK_MIME = "application/vnd.android.package-archive"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        SystemStatus.register(flutterEngine, this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "froggy/window")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setKeepAwake" -> {
                        val on = call.argument<Boolean>("on") ?: false
                        runOnUiThread {
                            if (on) {
                                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                            } else {
                                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                            }
                        }
                        result.success(null)
                    }
                    "isDefaultHome" -> result.success(isDefaultHome())
                    "openHomeSettings" -> {
                        openHomeSettings()
                        result.success(null)
                    }
                    "appVersion" -> result.success(appVersion())
                    "openUrl" -> result.success(openUrl(call.argument<String>("url")))
                    "installUpdate" -> {
                        result.success(installUpdate(call.argument<String>("url")))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun appVersion(): String {
        return try {
            packageManager.getPackageInfo(packageName, 0).versionName ?: ""
        } catch (_: Exception) {
            ""
        }
    }

    private fun openUrl(url: String?): Boolean {
        if (url.isNullOrEmpty()) return false
        return try {
            startActivity(
                Intent(Intent.ACTION_VIEW, Uri.parse(url))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun installUpdate(url: String?): Boolean {
        if (url.isNullOrEmpty()) return false
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                !packageManager.canRequestPackageInstalls()
            ) {
                try {
                    startActivity(
                        Intent(
                            Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                            Uri.parse("package:$packageName"),
                        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                } catch (_: Exception) {
                }
            }

            val file = File(
                getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS),
                "froggy-update.apk",
            )
            if (file.exists()) file.delete()

            val dm = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
            val request = DownloadManager.Request(Uri.parse(url))
                .setTitle("Froggy update")
                .setMimeType(APK_MIME)
                .setNotificationVisibility(
                    DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED
                )
                .setDestinationInExternalFilesDir(
                    this, Environment.DIRECTORY_DOWNLOADS, "froggy-update.apk"
                )
            val downloadId = dm.enqueue(request)

            val receiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    val id = intent.getLongExtra(
                        DownloadManager.EXTRA_DOWNLOAD_ID, -1
                    )
                    if (id != downloadId) return
                    try {
                        context.unregisterReceiver(this)
                    } catch (_: Exception) {
                    }
                    launchInstaller(file)
                }
            }
            ContextCompat.registerReceiver(
                this,
                receiver,
                IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE),
                ContextCompat.RECEIVER_EXPORTED,
            )
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun launchInstaller(file: File) {
        try {
            if (!file.exists()) return
            val uri = FileProvider.getUriForFile(
                this, "$packageName.fileprovider", file
            )
            startActivity(
                Intent(Intent.ACTION_VIEW)
                    .setDataAndType(uri, APK_MIME)
                    .addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_GRANT_READ_URI_PERMISSION
                    )
            )
        } catch (_: Exception) {
        }
    }

    private fun isDefaultHome(): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
            packageManager.resolveActivity(intent, 0)?.activityInfo?.packageName ==
                packageName
        } catch (_: Exception) {
            false
        }
    }

    private fun openHomeSettings() {
        try {
            startActivity(
                Intent(Settings.ACTION_HOME_SETTINGS)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
        } catch (_: Exception) {
            try {
                startActivity(
                    Intent(Settings.ACTION_SETTINGS)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                )
            } catch (_: Exception) {
            }
        }
    }
}
