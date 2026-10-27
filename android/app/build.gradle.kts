import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeyFile = rootProject.file("key.properties")
val releaseKeys = Properties().apply {
    if (releaseKeyFile.exists()) releaseKeyFile.inputStream().use { load(it) }
}
val allowDebugRelease = providers.environmentVariable("MATLINGO_ALLOW_DEBUG_SIGNING").orNull == "true"

if (releaseKeyFile.exists()) {
    for (name in listOf("storeFile", "storePassword", "keyAlias", "keyPassword")) {
        require(!releaseKeys.getProperty(name).isNullOrBlank()) {
            "Missing release signing property: $name in android/key.properties"
        }
    }
    require(rootProject.file(releaseKeys.getProperty("storeFile")).isFile) {
        "Release keystore not found. Check storeFile in android/key.properties."
    }
}

gradle.taskGraph.whenReady {
    if (!releaseKeyFile.exists() && !allowDebugRelease &&
        allTasks.any { it.project.path == ":app" && it.name.contains("Release") }) {
        throw GradleException(
            "Release signing is required. Configure android/key.properties using " +
                "android/key.properties.example. For a local test build only, set " +
                "MATLINGO_ALLOW_DEBUG_SIGNING=true. Never upload that test build to a store."
        )
    }
}

android {
    namespace = "com.learningstudio.brilliant_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.learningstudio.brilliant_mobile"
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
        if (releaseKeyFile.exists()) {
            create("release") {
                storeFile = rootProject.file(releaseKeys.getProperty("storeFile"))
                storePassword = releaseKeys.getProperty("storePassword")
                keyAlias = releaseKeys.getProperty("keyAlias")
                keyPassword = releaseKeys.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (releaseKeyFile.exists()) "release" else "debug"
            )
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
