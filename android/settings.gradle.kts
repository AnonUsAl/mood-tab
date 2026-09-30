pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // 版本依据（2026-09-30 实测升级）：
    //   Flutter 3.47.5 官方模板（flutter_tools/lib/src/android/gradle_utils.dart）= AGP 9.1.0 + Kotlin 2.4.0
    //   Flutter 检查器阈值（DependencyVersionChecker.kt）：
    //     warnAGP = 9.0.1 / warnKGP = 2.3.20 / warnGradle = 9.1.0
    //     errorAGP = 8.11.1 / errorKGP = 2.2.20 / errorGradle = 8.14.0
    //   旧值 8.11.1 + 2.2.20 恰好压在 error 线上 → 每次 flutter build 都打印「support will soon be dropped」。
    //
    // ⚠️ Kotlin 取模板值 2.4.0（≥ warnKGP，无告警）。
    // ⚠️ AGP 只敢取 9.0.1、没跟模板到 9.1.0：**AGP 9.1.0 要求 Gradle ≥ 9.3.1**，
    //    而本机下不到 Gradle 9.3.1（services.gradle.org 302 到 GitHub，JVM TLS 必被打断）。
    //    AGP 9.0.1 只要求 Gradle ≥ 9.1.0，正好是本机已缓存的版本 → 配置 + 编译均已实测通过。
    //    等哪天手工把 gradle-9.3.1-bin.zip 塞进 ~/.gradle/wrapper/dists，再一起升到 9.1.0。
    //
    // ⚠️ gradle.properties 里的 android.newDsl=false / android.builtInKotlin=false 必须保留：
    //   AGP 9 自带内置 Kotlin 且默认启用新 DSL，而 Flutter 的插件生态尚未全部迁移，
    //   这两个开关是 Flutter 官方给的过渡姿态（Flutter 模板同样写入它们）。
    //   保留的代价：AGP 9 会打印两条「option setting ... is deprecated」告警，属已知且无害；
    //   想消掉得整体迁到 built-in Kotlin，届时 package_info_plus / share_plus 仍在自行 apply KGP，风险高，先不动。
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")
