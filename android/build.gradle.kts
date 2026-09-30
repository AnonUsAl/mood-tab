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

// ⚠️ 让所有**插件子工程**统一按 compileSdk 36 编译 —— 别删。
//
// 起因（2026-09-30：AGP 8.11.1 → 9.0.1 之后 `flutter run` 直接失败）：
//
//     Execution failed for task ':file_picker:checkDebugAarMetadata'.
//       Dependency ':flutter_plugin_android_lifecycle' requires libraries and applications
//       that depend on it to compile against version 36 or later of the Android APIs.
//       :file_picker is currently compiled against android-34.
//
// 根因：`file_picker 8.3.7` 的 android/build.gradle **硬编码 `compileSdk 34`**，
// 而它依赖的 `flutter_plugin_android_lifecycle 2.0.35` 的 AAR 元数据要求消费方 ≥ 36。
// **AGP 8 不对 library 模块强制这条检查，AGP 9 开始强制**（实测同一个
// `:file_picker:checkDebugAarMetadata` 任务：AGP 8.11.1 → BUILD SUCCESSFUL，9.0.1 → BUILD FAILED）
// —— 所以是「升 AGP 把老插件的问题顶到台面上」，不是插件坏了。
//
// 为什么改这里而不是改插件本身的 build.gradle：直接改 `~/.pub-cache` 里的文件会被下一次
// `pub get` 冲掉；升级 file_picker 到 9+ 是另一件事（API 有破坏性变更），不夹带。
// 等实际用到的插件都自己写上 `compileSdk = flutter.compileSdkVersion` 后，这段可以删。
subprojects {
    val unifyCompileSdk: () -> Unit = {
        val androidExt = extensions.findByName("android")
        if (androidExt != null) {
            // 用 withGroovyBuilder 动态调用，而不是直接引用 BaseExtension：
            // 根脚本的 buildscript classpath **不保证**有 AGP（AGP 是在
            // settings.gradle.kts 的 plugins 块里声明的），写死类型名可能在脚本编译期就报错。
            runCatching {
                androidExt.withGroovyBuilder { "compileSdkVersion"(36) }
            }.onFailure { e ->
                logger.warn(
                    "[compileSdk 统一] ${project.name} 设置失败：${e.message}；" +
                        "如果后续再报 AAR metadata 不满足，就是它没生效"
                )
            }
        }
    }
    // ⚠️ 顺序有讲究：本块必须排在下面 `evaluationDependsOn(":app")` 之前，
    // 且要处理「已经被评估过」的情况 —— 否则会抛
    // `Cannot run Project.afterEvaluate(Action) when the project is already evaluated`
    // （configuration-on-demand 打开时尤其容易撞上）。
    if (state.executed) unifyCompileSdk() else afterEvaluate { unifyCompileSdk() }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
