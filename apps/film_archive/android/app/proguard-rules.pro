## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

## Retrofit / OkHttp (used via networking package with dio + retrofit)
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keepattributes Signature
-keepattributes Exceptions

-dontwarn okhttp3.**
-dontwarn okio.**

## Gson (used by dio for JSON serialization)
-keep class com.google.gson.** { *; }
-keepattributes *Annotation*

## Kotlin serialization / reflection
-dontwarn kotlin.**
-dontwarn kotlinx.**

## AndroidX
-dontwarn androidx.**
