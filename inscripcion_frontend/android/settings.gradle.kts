pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            try {
                val propsFile = settingsDir.resolve("local.properties")
                if (propsFile.exists()) {
                    propsFile.inputStream().use { properties.load(it) }
                } else {
                    val rootProps = file("../local.properties")
                    if (rootProps.exists()) {
                        rootProps.inputStream().use { properties.load(it) }
                    }
                }
            } catch (e: Exception) {
                // Silently fail to avoid blocking the IDE, fallback to environment or default
            }
            properties.getProperty("flutter.sdk") ?: "C:/src/flutter"
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
