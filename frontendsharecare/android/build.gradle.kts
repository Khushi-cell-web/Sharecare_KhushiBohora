allprojects {
    repositories {
        google()
        mavenCentral()
        val esewaDir = file("${rootProject.projectDir.parentFile.absolutePath}/eSewa Flutter Sdk v2.5.4_24/esewa_flutter_sdk/android/libs")
        flatDir {
            dirs(esewaDir.absolutePath)
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
