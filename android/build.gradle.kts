allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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

// Do not override Java/Kotlin targets globally; allow each module to define its own

// Align Kotlin jvmTarget with each module's Java target to prevent mismatch errors
subprojects {
    plugins.withId("org.jetbrains.kotlin.android") {
        tasks.matching { it.name.startsWith("compile") }.configureEach {
            // Ensure Kotlin tasks use the same JVM target as Java tasks in the same module
            if (this is org.jetbrains.kotlin.gradle.tasks.KotlinCompile) {
                val javaTask = tasks.withType<org.gradle.api.tasks.compile.JavaCompile>().firstOrNull()
                val javaTarget = javaTask?.targetCompatibility?.toString()
                if (!javaTarget.isNullOrBlank()) {
                    kotlinOptions.jvmTarget = javaTarget
                }
            }
        }
    }
}
