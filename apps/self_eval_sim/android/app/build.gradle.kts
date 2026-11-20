plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.spiralmomentum.self_eval_sim"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.spiralmomentum.self_eval_sim"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 온디바이스 모델(LiteRT-LM)이 arm64-v8a 전용이라 다른 ABI 라이브러리는 패키징에서 뺀다.
    // flutter_gemma 가 함께 넣는 라이브러리 중 이 앱이 쓰지 않는 것(NPU QNN, 비전/이미지 생성, RAG 벡터DB)은 뺀다.
    packaging {
        jniLibs {
            excludes += listOf(
                "**/libQnn*.so",
                "**/libLiteRtDispatch_Qualcomm.so",
                "**/libimagegenerator_gpu.so",
                "**/libmediapipe_tasks_vision_image_generator_jni.so",
                "**/libmediapipe_tasks_vision_jni.so",
                "**/libqdrant_edge_ffi.so",
                // arm64-v8a 외 ABI (플러그인 AAR 에 들어 있는 것까지)
                "lib/armeabi-v7a/**",
                "lib/x86/**",
                "lib/x86_64/**",
            )
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
