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

    // Backfill `namespace` for Android library plugins still using the legacy
    // `package=` attribute in AndroidManifest.xml (required by AGP 8+).
    // Reflection avoids needing AGP types on this build script's classpath.
    afterEvaluate {
        val ext = extensions.findByName("android") ?: return@afterEvaluate
        try {
            val getNs = ext.javaClass.getMethod("getNamespace")
            if (getNs.invoke(ext) != null) return@afterEvaluate
            val manifest = file("src/main/AndroidManifest.xml")
            if (!manifest.exists()) return@afterEvaluate
            val pkg = Regex("""package\s*=\s*"([^"]+)"""")
                .find(manifest.readText())?.groupValues?.get(1)
                ?: return@afterEvaluate
            ext.javaClass.getMethod("setNamespace", String::class.java).invoke(ext, pkg)
        } catch (_: Exception) {
            // Plugin already migrated or AGP API changed — leave as-is.
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
