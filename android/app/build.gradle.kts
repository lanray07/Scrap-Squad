plugins { id("com.android.application") }
android {
    namespace = "com.scrapsquad.fire"
    compileSdk = 36
    defaultConfig {
        applicationId = "com.scrapsquad.fire"
        minSdk = 28
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
        val privacyUrl = providers.environmentVariable("SCRAP_ANDROID_PRIVACY_URL").orElse("").get()
        buildConfigField("String", "PRIVACY_POLICY_URL", "\"" + privacyUrl.replace("\\", "\\\\").replace("\"", "\\\"") + "\"")
        ndk { abiFilters += listOf("arm64-v8a", "x86_64") }
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }
    compileOptions { sourceCompatibility = JavaVersion.VERSION_17; targetCompatibility = JavaVersion.VERSION_17 }
    buildFeatures { buildConfig = true }
    packaging { jniLibs.useLegacyPackaging = true }
    signingConfigs {
        create("release") {
            val path = providers.environmentVariable("SCRAP_ANDROID_KEYSTORE").orNull
            if (path != null) {
                storeFile = file(path)
                storePassword = providers.environmentVariable("SCRAP_ANDROID_STORE_PASSWORD").orNull
                keyAlias = providers.environmentVariable("SCRAP_ANDROID_KEY_ALIAS").orNull
                keyPassword = providers.environmentVariable("SCRAP_ANDROID_KEY_PASSWORD").orNull
            }
        }
    }
    buildTypes {
        release { signingConfig = signingConfigs.getByName("release"); isMinifyEnabled = false }
    }
}
val natives by configurations.creating
dependencies {
    implementation("androidx.core:core:1.17.0")
    implementation("com.amazon.device:amazon-appstore-sdk:3.0.9")
    implementation("com.badlogicgames.gdx:gdx:1.14.2")
    implementation("com.badlogicgames.gdx:gdx-backend-android:1.14.2")
    add("natives", "com.badlogicgames.gdx:gdx-platform:1.14.2:natives-arm64-v8a")
    add("natives", "com.badlogicgames.gdx:gdx-platform:1.14.2:natives-x86_64")
    androidTestImplementation("androidx.test:runner:1.7.0")
    androidTestImplementation("androidx.test.ext:junit:1.3.0")
}
tasks.register<Copy>("copyGdxNatives") {
    natives.forEach { archive ->
        from(zipTree(archive)) {
            include("*.so")
            into(if (archive.name.contains("arm64")) "arm64-v8a" else "x86_64")
        }
    }
    includeEmptyDirs = false
    into("src/main/jniLibs")
}
tasks.named("preBuild") { dependsOn("copyGdxNatives") }
