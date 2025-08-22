plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

android {
    namespace = "com.example.medico_app"
    compileSdk = 34 // Você pode ajustar para a versão que o Flutter recomenda
    ndkVersion = "25.1.8937393" // Verifique a versão recomendada pelo Flutter

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    defaultConfig {
        applicationId = "com.example.medico_app"
        minSdk = 21
        targetSdk = 34
        versionCode = flutterVersionCode.toInteger()
        versionName = flutterVersionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.1.1"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.22") // Verifique a versão do Kotlin
}