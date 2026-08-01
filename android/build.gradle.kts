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

// Force every Android plugin module to compile against SDK 36. The app-level
// `compileSdk` does not propagate to plugin subprojects, so plugins that build
// against an older SDK (e.g. file_picker against android-34) fail the AAR
// metadata check imposed by flutter_plugin_android_lifecycle, which requires
// consumers to compile against SDK 36 or later.
subprojects {
    fun forceCompileSdk(target: Project) {
        val androidExtension = target.extensions.findByName("android") ?: return
        val methods = androidExtension.javaClass.methods
        val setCompileSdk = methods.firstOrNull {
            it.name == "setCompileSdk" && it.parameterTypes.size == 1 &&
                (it.parameterTypes[0] == Int::class.javaPrimitiveType ||
                    it.parameterTypes[0] == Integer::class.java)
        }
        if (setCompileSdk != null) {
            setCompileSdk.invoke(androidExtension, 36)
        } else {
            methods.firstOrNull {
                it.name == "setCompileSdkVersion" && it.parameterTypes.size == 1 &&
                    it.parameterTypes[0] == Int::class.javaPrimitiveType
            }?.invoke(androidExtension, 36)
        }
    }
    // `:app` is evaluated eagerly (via evaluationDependsOn above), so calling
    // afterEvaluate on it would fail with "project is already evaluated".
    // Guard by configuring already-evaluated projects immediately and only
    // deferring the rest.
    if (state.executed) {
        forceCompileSdk(project)
    } else {
        afterEvaluate { forceCompileSdk(project) }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
