plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.9.0"))
    implementation(files("libs/spotify-app-remote-release-0.8.0.aar"))
    implementation(("com.spotify.android:auth:2.1.0" ))
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

        manifestPlaceholders["appAuthRedirectScheme"] = "medrhythms"
        manifestPlaceholders["redirectHostName"] = "callback"
        manifestPlaceholders["redirectSchemeName"] = "medrhythms"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    lintOptions {
        isCheckReleaseBuilds = false
    }
}

flutter {
    source = "../.."
}