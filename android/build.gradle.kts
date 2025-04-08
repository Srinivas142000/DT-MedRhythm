import org.gradle.api.tasks.Delete
import com.android.build.gradle.BaseExtension

buildscript {
    val kotlin_version by extra("1.9.24")
    
    repositories {
        google()
        mavenCentral()
        flatDir {
            dirs("libs")
        }
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
        maven { url = uri("https://jitpack.io") } // For plugins/artifacts on JitPack
        flatDir {
            dirs("libs")
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

// Configure Android projects (application and library)
// subprojects {
//     // For Android applications
//     plugins.withId("com.android.application") {
//         extensions.configure<BaseExtension> {
//             defaultConfig {
//                 minSdk = 21
//                 targetSdk = 34
//             }
//             compileOptions {
//                 sourceCompatibility = JavaVersion.VERSION_11
//                 targetCompatibility = JavaVersion.VERSION_11
//             }
//         }
//     }
//     // For Android libraries
//     plugins.withId("com.android.library") {
//         extensions.configure<BaseExtension> {
//             compileSdkVersion(34)
//             defaultConfig {
//                 minSdk = 21
//                 targetSdk = 34
//             }
//             compileOptions {
//                 sourceCompatibility = JavaVersion.VERSION_11
//                 targetCompatibility = JavaVersion.VERSION_11
//             }
//         }
//     }
// }