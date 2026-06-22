package com.srinista.vachika_lekhini

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val phoneModeChannel = "vachika_lekhini/phone_mode"
    private val ringerModeChannel = "vachika_lekhini/ringer_mode"
    private val ringerModeEventsChannel = "vachika_lekhini/ringer_mode_events"

    private var ringerReceiver: BroadcastReceiver? = null
    private var ringerEvents: EventChannel.EventSink? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableFullscreen()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, phoneModeChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "toggle" -> result.success(togglePhoneMode())
                    "isEnabled" -> result.success(isPhoneModeEnabled())
                    "openSettings" -> {
                        openNotificationPolicySettings()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ringerModeChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getRingerMode" -> result.success(currentRingerMode())
                    "cycleRingerMode" -> result.success(cycleRingerMode())
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, ringerModeEventsChannel)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    ringerEvents = events
                    // Emit the current value immediately, then on every change.
                    events?.success(currentRingerMode())
                    ringerReceiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            if (intent?.action == AudioManager.RINGER_MODE_CHANGED_ACTION) {
                                events?.success(currentRingerMode())
                            }
                        }
                    }
                    val filter = IntentFilter(AudioManager.RINGER_MODE_CHANGED_ACTION)
                    // Android 13+ (API 33+) requires an explicit export flag for
                    // runtime receivers — without it the registration fails and
                    // we never get live ringer updates from the OS.
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        registerReceiver(ringerReceiver, filter, Context.RECEIVER_EXPORTED)
                    } else {
                        @Suppress("UnspecifiedRegisterReceiverFlag")
                        registerReceiver(ringerReceiver, filter)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    ringerReceiver?.let { runCatching { unregisterReceiver(it) } }
                    ringerReceiver = null
                    ringerEvents = null
                }
            })
    }

    private fun audioManager(): AudioManager =
        getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private fun currentRingerMode(): String =
        when (audioManager().ringerMode) {
            AudioManager.RINGER_MODE_SILENT -> "silent"
            AudioManager.RINGER_MODE_VIBRATE -> "vibrate"
            AudioManager.RINGER_MODE_NORMAL -> "normal"
            else -> "unknown"
        }

    // Cycle normal → vibrate → silent → normal. Switching to/from silent or
    // vibrate on Android M+ needs Do-Not-Disturb policy access; if missing,
    // send the user to grant it and leave the mode unchanged.
    private fun cycleRingerMode(): String {
        val manager = audioManager()
        val current = manager.ringerMode
        val next = when (current) {
            AudioManager.RINGER_MODE_NORMAL -> AudioManager.RINGER_MODE_VIBRATE
            AudioManager.RINGER_MODE_VIBRATE -> AudioManager.RINGER_MODE_SILENT
            else -> AudioManager.RINGER_MODE_NORMAL
        }

        // DND access is required to set silent OR vibrate on Android M+.
        // Also required to escape from silent on some devices/OEMs.
        val needsAccess = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            !hasNotificationPolicyAccess()
        if (needsAccess) {
            openNotificationPolicySettings()
            return currentRingerMode()
        }

        try {
            manager.ringerMode = next
            // Setting RINGER_MODE_SILENT alone is insufficient on Android 6+ — the OS
            // may still ring for calls unless DND is also engaged. Conversely, restoring
            // normal mode must lift DND so calls flow through again.
            if (hasNotificationPolicyAccess()) {
                val nm = notificationManager()
                when (next) {
                    AudioManager.RINGER_MODE_SILENT ->
                        nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
                    AudioManager.RINGER_MODE_NORMAL ->
                        nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                    // Vibrate: leave DND as-is; vibrate still lets priority calls through.
                }
            }
        } catch (e: SecurityException) {
            // DND access revoked at runtime — prompt user and bail.
            openNotificationPolicySettings()
            return currentRingerMode()
        }

        // Push the new state to the UI immediately so the app reflects the tap
        // even before the system RINGER_MODE_CHANGED broadcast arrives.
        val now = currentRingerMode()
        ringerEvents?.success(now)
        return now
    }

    override fun onResume() {
        super.onResume()
        // The ringer may have been changed in the system while we were away;
        // re-sync the latest value to the UI on every foreground.
        ringerEvents?.success(currentRingerMode())
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            enableFullscreen()
        }
    }

    private fun enableFullscreen() {
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes = window.attributes.apply {
                layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
            window.insetsController?.let { controller ->
                controller.hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                controller.systemBarsBehavior =
                    WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility =
                View.SYSTEM_UI_FLAG_FULLSCREEN or
                    View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                    View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
                    View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                    View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                    View.SYSTEM_UI_FLAG_LAYOUT_STABLE
        }
    }

    private fun notificationManager(): NotificationManager =
        getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun hasNotificationPolicyAccess(): Boolean =
        notificationManager().isNotificationPolicyAccessGranted

    private fun isPhoneModeEnabled(): Boolean {
        if (!hasNotificationPolicyAccess()) return false
        return notificationManager().currentInterruptionFilter ==
            NotificationManager.INTERRUPTION_FILTER_NONE
    }

    private fun togglePhoneMode(): String {
        if (!hasNotificationPolicyAccess()) {
            openNotificationPolicySettings()
            return "permission_required"
        }

        val manager = notificationManager()
        val nextFilter =
            if (manager.currentInterruptionFilter == NotificationManager.INTERRUPTION_FILTER_NONE) {
                NotificationManager.INTERRUPTION_FILTER_ALL
            } else {
                NotificationManager.INTERRUPTION_FILTER_NONE
            }
        manager.setInterruptionFilter(nextFilter)
        return if (nextFilter == NotificationManager.INTERRUPTION_FILTER_NONE) "enabled" else "disabled"
    }

    private fun openNotificationPolicySettings() {
        startActivity(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
    }
}
