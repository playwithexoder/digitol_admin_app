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
    afterEvaluate {
        val project = this
        if (project.hasProperty("android")) {
            val extension = project.extensions.findByName("android")
            if (extension != null) {
                try {
                    extension.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType).invoke(extension, 36)
                } catch (e: Exception) {
                    try {
                        extension.javaClass.getMethod("setCompileSdkVersion", String::class.java).invoke(extension, "android-36")
                    } catch (e2: Exception) {
                    }
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
