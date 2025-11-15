import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("app/keystore.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { stream ->
        keystoreProperties.load(stream)
    }
}

// 从项目属性读取appEdition，默认为"lite"
val appEdition = project.findProperty("appEdition") as String? ?: "lite"
val packageName = when (appEdition) {
    "lite" -> "com.granoflow.lite"
    "pro" -> "com.granoflow.pro"
    else -> "com.granoflow.app" // 默认值，用于向后兼容
}

android {
    namespace = packageName
    compileSdk = flutter.compileSdkVersion
    // 使用 NDK r29 以支持 16 KB 页面大小（Android 16+）
    // Flutter 3.35.1 默认使用 r27，不支持 16 KB
    ndkVersion = "29.0.13846066"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // 启用 core library desugaring（flutter_local_notifications 需要）
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = packageName
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // 支持 16 KB 页面大小（Android 16+）
        // 只支持 arm64-v8a 和 x86_64 架构
        ndk {
            abiFilters += listOf("arm64-v8a", "x86_64")
        }
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    bundle {
        language {
            enableSplit = false
        }
        density {
            enableSplit = false
        }
        abi {
            enableSplit = false
        }
    }
    
    // 支持 16 KB 页面大小（Android 16+）
    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }
    
    // 根据appEdition配置源目录
    // 注意：由于包名不同，每个版本的MainActivity.kt必须存在于对应的包目录中
    // Gradle会根据namespace自动选择正确的源文件
    sourceSets {
        getByName("main") {
            java {
                // 包含所有版本的源目录，Gradle会根据namespace选择正确的文件
                srcDirs("src/main/kotlin")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring（flutter_local_notifications 需要）
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
