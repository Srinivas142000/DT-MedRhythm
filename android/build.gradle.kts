buildscript {
    val kotlin_version = "1.9.24"
    
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io")}
    }
    
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
        classpath("com.google.gms:google-services:4.3.15")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io")}
    }

     configurations.all {
        resolutionStrategy {
            force("com.github.spotify.android-sdk:app-remote-lib:v0.8.0-appremote_v2.1.0-auth")
        }
    }
}

rootProject.buildDir = file("../build")
subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
