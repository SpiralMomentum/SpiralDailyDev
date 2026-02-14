## Flutter-specific ProGuard rules

# Keep Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep Dart entry points
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
