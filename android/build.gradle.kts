import com.android.build.gradle.BaseExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Some Flutter plugins still declare compileSdk 33 even though their
// AndroidX dependencies require API 34+. Keep every Android subproject on
// the SDK installed for this project.
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<BaseExtension> {
            compileSdkVersion(36)
        }
    }
    plugins.withId("com.android.application") {
        extensions.configure<BaseExtension> {
            compileSdkVersion(36)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
