plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.9.0"))
    implementation("com.github.spotify.android-sdk:app-remote-lib:v0.8.0-appremote_v2.1.0-auth")
    implementation("androidx.core:core-ktx:1.7.0")
    implementation("androidx.appcompat:appcompat:1.4.0")
}



android {
    namespace = "com.example.medrhythms"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.medrhythms"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName


        // manifestPlaceholders[appAuthRedirectSchemeName] = "spotify-sdk"
        manifestPlaceholders["appAuthRedirectScheme"] = "com.redirectScheme.comm"
        manifestPlaceholders["redirectHostName"] = "auth"
        manifestPlaceholders["redirectSchemeName"] = "medrhythms"

    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false   // Disable resource shrinking
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    lintOptions {
        isCheckReleaseBuilds = false
    }
}

flutter {
    source = "../.."
}
