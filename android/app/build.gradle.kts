plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.gestion_betail"
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.gestion_betail"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    packagingOptions {
        exclude("META-INF/proguard/androidx-*.pro")
    }
}

// ✅ SOLUTION COMPLÈTE : Force + Exclut les vieilles versions
configurations.all {
    resolutionStrategy {
        // Force la version 1.8.10
        force("org.jetbrains.kotlin:kotlin-stdlib:1.8.10")
        
        // Exclure les vieilles versions pour qu'elles ne soient jamais incluses
        eachDependency { details ->
            if (details.requested.group == "org.jetbrains.kotlin") {
                if (details.requested.name in listOf(
                    "kotlin-stdlib-jdk7",
                    "kotlin-stdlib-jdk8"
                )) {
                    details.exclude()
                }
            }
        }
    }
}

flutter {
    source = "../.."
}