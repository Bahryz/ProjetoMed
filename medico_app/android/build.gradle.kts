// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Firebase plugin
    kotlin("android") // se usar Kotlin
}

android {
    namespace = "com.seuapp.exemplo"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.seuapp.exemplo"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

dependencies {
    // Firebase BoM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:33.13.0"))

    // Firebase SDKs
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")

     
}
