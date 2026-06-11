# ── JNA (Vosk native bridge) ────────────────────────────────────────────────
-keep class com.sun.jna.* { *; }
-keepclassmembers class * extends com.sun.jna.* { public *; }
-dontwarn java.awt.Component
-dontwarn java.awt.GraphicsEnvironment
-dontwarn java.awt.HeadlessException
-dontwarn java.awt.Window

# ── Vosk ASR ─────────────────────────────────────────────────────────────────
-keep class org.vosk.** { *; }
-dontwarn org.vosk.**

# ── App package — keep everything to avoid R8 stripping generated code ───────
-keep class com.srinista.vachika_lekhini.** { *; }

# ── Flutter / Dart embedding ─────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.**

# ── Drift / SQLite (generated DAOs, table classes, database impl) ─────────────
-keep class ** extends drift.GeneratedDatabase { *; }
-keep class ** extends drift.DatabaseAccessor { *; }
-keep @drift.DriftDatabase class * { *; }
-keep @drift.DriftAccessor class * { *; }
-keepclassmembers class * {
    @drift.internal.* *;
}
-dontwarn drift.**

# ── Hive (generated TypeAdapters must survive shrinking) ─────────────────────
-keep class ** extends com.hivedb.hive.HiveObject { *; }
-keep class **TypeAdapter { *; }
-keepnames class * implements com.hivedb.hive.HiveType
-dontwarn com.hivedb.**

# ── freezed / json_serializable generated classes ────────────────────────────
-keep class **.freezed.** { *; }
-keep class **$** implements ** { *; }
-keepclassmembers class * {
    **.fromJson(**);
    **.toJson();
}

# ── Riverpod ──────────────────────────────────────────────────────────────────
-keep class dev.rvpd.** { *; }
-dontwarn dev.rvpd.**

# ── flutter_local_notifications ───────────────────────────────────────────────
-keep class com.dexterous.** { *; }
-keep class androidx.work.** { *; }
-dontwarn com.dexterous.**

# ── Dio / OkHttp networking ───────────────────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# ── Kotlin coroutines ─────────────────────────────────────────────────────────
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}
-dontwarn kotlinx.**
