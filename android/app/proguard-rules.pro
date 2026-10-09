# Suppress all missing optional class warnings
-ignorewarnings

-dontwarn com.google.mlkit.vision.text.**
-dontwarn com.google.mlkit.vision.common.**
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.**

# Keep ML Kit classes
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }

# Flutter & plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }