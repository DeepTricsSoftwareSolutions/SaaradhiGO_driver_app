import java.io.File

// Ensure Flutter can find artifacts under `<flutter_project>/build/`.
// Without this, Gradle defaults to `<flutter_project>/android/**/build/` and
// `flutter build apk` may fail to locate the produced APK on some setups.
rootProject.layout.buildDirectory.set(file("../build"))

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    project.layout.buildDirectory.set(
        File(rootProject.layout.buildDirectory.get().asFile, project.name)
    )
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
