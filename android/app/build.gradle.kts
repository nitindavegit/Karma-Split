plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.karmasplit.karma_split"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Application ID and version settings
        applicationId = "com.karmasplit.karma_split"
        minSdk = 23
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        // Enable multidex support for large apps
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Enable code shrinking and obfuscation
            isMinifyEnabled = false  // Disable for now due to R8 issues
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // Use debug signing for now (can be replaced with release keystore)
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    dependencies {
        implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
        implementation("com.google.firebase:firebase-auth")
        implementation("com.google.android.gms:play-services-auth:20.7.0")
    }
}

flutter {
    source = "../.."
}
