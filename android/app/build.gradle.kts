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

dependencies {
    // Exclude old Kotlin versions from all dependencies
    all {
        exclude(group = "org.jetbrains.kotlin", module = "kotlin-stdlib-jdk7")
        exclude(group = "org.jetbrains.kotlin", module = "kotlin-stdlib-jdk8")
    }
}

configurations.all {
    resolutionStrategy {
        force("org.jetbrains.kotlin:kotlin-stdlib:1.8.10")
        force("org.jetbrains.kotlin:kotlin-stdlib-common:1.8.10")
        
        eachDependency { details ->
            if (details.requested.group == "org.jetbrains.kotlin") {
                when (details.requested.name) {
                    "kotlin-stdlib-jdk7", "kotlin-stdlib-jdk8" -> {
                        details.useTarget("org.jetbrains.kotlin:kotlin-stdlib:1.8.10")
                    }
                }
            }
        }
    }
    
    exclude(group = "org.jetbrains.kotlin", module = "kotlin-stdlib-jdk7")
    exclude(group = "org.jetbrains.kotlin", module = "kotlin-stdlib-jdk8")
}

flutter {
    source = "../.."
}