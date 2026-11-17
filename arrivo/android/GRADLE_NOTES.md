# android/app/build.gradle changes (Groovy version; adapt for build.gradle.kts)

android {
    compileSdkVersion 35          // or flutter.compileSdkVersion if it is 34+
    defaultConfig {
        minSdkVersion 23          // required by the background service and notifications
        targetSdkVersion 34
    }
    compileOptions {
        coreLibraryDesugaringEnabled true   // required by flutter_local_notifications
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'
}
