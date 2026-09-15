import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

/// Release signing props: env vars first (CI secrets), then
/// `android/keystore.properties` (local builds). Null when absent.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("keystore.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

fun signingProp(name: String): String? =
    System.getenv(name) ?: keystoreProperties.getProperty(name)

android {
    namespace = "com.geerxlabs.geergitroothelper"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.geerxlabs.geergitroothelper"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storePass = signingProp("RELEASE_STORE_PASSWORD")
            if (storePass != null) {
                storeFile = file(signingProp("RELEASE_KEYSTORE_PATH") ?: "geergit-root-helper.keystore")
                storePassword = storePass
                keyAlias = signingProp("RELEASE_KEY_ALIAS") ?: "grh"
                keyPassword = signingProp("RELEASE_KEY_PASSWORD") ?: storePass
            }
        }
    }

    buildTypes {
        release {
            // Signed with the release keystore when secrets are present
            // (env on CI, keystore.properties locally); debug fallback
            // keeps unsigned/fork builds working. See
            // docs/plans/0005-release-build-ci.md.
            signingConfig =
                if (signingConfigs.getByName("release").storePassword != null) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
    }

    packaging {
        jniLibs {
            // Extract libmagiskboot.so at install: it must be a real file in
            // nativeLibraryDir so the app can exec it (W^X blocks app_data_file).
            useLegacyPackaging = true
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
