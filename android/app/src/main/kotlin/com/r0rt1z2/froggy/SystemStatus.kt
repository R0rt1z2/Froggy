package com.r0rt1z2.froggy

import android.app.UiModeManager
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.media.AudioManager
import android.media.MediaMetadata
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object SystemStatus {
    private const val CHANNEL = "froggy/system_status"

    fun register(engine: FlutterEngine, context: Context) {
        val appCtx = context.applicationContext
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "get" -> result.success(snapshot(appCtx))
                    "isTelevision" -> result.success(isTelevision(appCtx))
                    "hasNotificationAccess" ->
                        result.success(hasNotificationAccess(appCtx))
                    "openNotificationAccess" -> {
                        openNotificationAccess(appCtx)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun snapshot(context: Context): Map<String, Any> {
        val out = HashMap<String, Any>()

        var wifiConnected = false
        var wifiLevel = 0
        try {
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE)
                    as ConnectivityManager
            val caps = cm.getNetworkCapabilities(cm.activeNetwork)
            wifiConnected =
                caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
            if (wifiConnected) {
                val wm = context.getSystemService(Context.WIFI_SERVICE) as WifiManager
                @Suppress("DEPRECATION")
                val rssi = wm.connectionInfo.rssi
                @Suppress("DEPRECATION")
                wifiLevel = WifiManager.calculateSignalLevel(rssi, 5)
            }
        } catch (_: Exception) {
        }
        out["wifiConnected"] = wifiConnected
        out["wifiLevel"] = wifiLevel

        var bluetoothConnected = false
        try {
            val bm = context.getSystemService(Context.BLUETOOTH_SERVICE)
                    as BluetoothManager
            val adapter = bm.adapter
            if (adapter != null && adapter.isEnabled) {
                val a2dp = adapter.getProfileConnectionState(BluetoothProfile.A2DP)
                val headset =
                    adapter.getProfileConnectionState(BluetoothProfile.HEADSET)
                bluetoothConnected = a2dp == BluetoothProfile.STATE_CONNECTED ||
                        headset == BluetoothProfile.STATE_CONNECTED
            }
        } catch (_: Exception) {
        }
        out["bluetoothConnected"] = bluetoothConnected

        var musicActive = false
        try {
            val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            musicActive = am.isMusicActive
        } catch (_: Exception) {
        }
        out["musicActive"] = musicActive

        var musicTitle = ""
        try {
            val msm = context.getSystemService(Context.MEDIA_SESSION_SERVICE)
                    as MediaSessionManager
            val comp = ComponentName(context, FroggyNotificationListener::class.java)
            val sessions = msm.getActiveSessions(comp)
            var fallback = ""
            for (c in sessions) {
                val md = c.metadata ?: continue
                val title = md.getString(MediaMetadata.METADATA_KEY_TITLE) ?: ""
                if (title.isEmpty()) continue
                val artist = md.getString(MediaMetadata.METADATA_KEY_ARTIST) ?: ""
                val label = if (artist.isNotEmpty()) "$title — $artist" else title
                if (c.playbackState?.state == PlaybackState.STATE_PLAYING) {
                    musicTitle = label
                    break
                }
                if (fallback.isEmpty()) fallback = label
            }
            if (musicTitle.isEmpty()) musicTitle = fallback
        } catch (_: Exception) {
        }
        out["musicTitle"] = musicTitle

        return out
    }

    private fun isTelevision(context: Context): Boolean {
        return try {
            val ui = context.getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
            if (ui.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION) return true
            val pm = context.packageManager
            pm.hasSystemFeature(PackageManager.FEATURE_LEANBACK) ||
                pm.hasSystemFeature(PackageManager.FEATURE_TELEVISION)
        } catch (_: Exception) {
            false
        }
    }

    private fun hasNotificationAccess(context: Context): Boolean {
        return try {
            val flat = Settings.Secure.getString(
                context.contentResolver, "enabled_notification_listeners"
            ) ?: return false
            val pkg = context.packageName
            flat.split(":").any { it.contains(pkg) }
        } catch (_: Exception) {
            false
        }
    }

    private fun openNotificationAccess(context: Context) {
        try {
            val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        } catch (_: Exception) {
        }
    }
}
