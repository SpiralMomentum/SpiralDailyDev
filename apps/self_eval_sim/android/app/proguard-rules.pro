# flutter_gemma (MediaPipe / LiteRT-LM) - README 권장 규칙
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**
# R8 이 생성한 누락 클래스 경고 억제 (build/app/outputs/mapping/release/missing_rules.txt)
-dontwarn com.google.auto.value.extension.memoized.Memoized
