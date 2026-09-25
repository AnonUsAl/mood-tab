import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 上一次桌面端数据库工厂初始化失败的原因；成功时为 null。
///
/// 单独立一份是因为底层抛出来的往往是一句很难读的 ffi 异常，
/// 而这里能补上「到底缺了什么」—— Windows 上最常见的就是应用目录里
/// 没有原生 sqlite3 库。页面层拿它来给用户提示。
String? desktopDatabaseFactoryError;

/// 桌面端数据库工厂初始化（有 dart:io 的平台使用本实现）。
///
/// `sqflite` 本体只实现了 Android / iOS / macOS，
/// Windows 与 Linux 上 `databaseFactory` 没有被任何插件设置过，
/// 直接调用 `openDatabase` 会抛 "databaseFactory not initialized"，
/// 表现为「页面全空、记录也存不进去」。
///
/// 这两个平台需要切到 sqflite 的 FFI 实现。原生 sqlite3 库由
/// `package:sqlite3` 的 code asset 在构建时自动打进应用包
/// （见 `windows/CMakeLists.txt` 里安装 `native_assets` 的那一段），
/// 不需要手动往 exe 旁边放 sqlite3.dll —— **但前提是那个库真的被装进了包**。
///
/// ⚠️ `sqlite3` 3.x 用的是 Dart 的 code asset（`@ffi.DefaultAsset`）来解析
/// 原生库，**没有 `DynamicLibrary.open` 的运行时兜底**。库一旦缺失，
/// 这里就会抛错，而且没法在运行时改成从别处加载 —— 只能把包装对。
/// 所以初始化失败时要把原因记录下来，让上层能明确告诉用户。
///
/// 其他平台（Android / iOS / macOS）保持原生实现，这里什么都不做。
void initDesktopDatabaseFactory() {
  if (defaultTargetPlatform != TargetPlatform.windows &&
      defaultTargetPlatform != TargetPlatform.linux) {
    return;
  }

  try {
    // Windows 上这一步会真的去加载原生 sqlite3 库
    // （sqflite_common_ffi 的 windowsInit 会在主 isolate 里开一个内存库再关掉，
    //  因为在 isolate 里加载在 Windows 上会出问题）。库缺失就在这里炸。
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    desktopDatabaseFactoryError = null;
  } catch (e) {
    desktopDatabaseFactoryError = _describeInitFailure(e);
    debugPrint('桌面端数据库初始化失败: $e');
    rethrow;
  }
}

/// 把原生库加载失败翻译成「缺什么、放哪儿」。
String _describeInitFailure(Object error) {
  final buffer = StringBuffer('原生 SQLite 库加载失败，本地数据库无法使用。');

  if (Platform.isWindows) {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = <String>[
      p.join(exeDir, 'sqlite3.dll'),
      p.join(exeDir, 'data', 'sqlite3.dll'),
    ];
    final present = candidates.where((c) => File(c).existsSync()).toList();

    buffer.write('\n\n应用目录：$exeDir');
    if (present.isEmpty) {
      buffer.write(
        '\n❌ 应用目录里没有 sqlite3.dll。'
        '\n打包时需要把构建产物里的 sqlite3.dll（mood_tab.exe 同级）一起分发，'
        '只复制 mood_tab.exe 和 data 目录是不够的。',
      );
    } else {
      buffer.write('\n✅ 找到 ${present.join('、')}，但加载仍然失败，可能是文件损坏或架构不符。');
    }
  }

  buffer.write('\n\n原始错误：$error');
  return buffer.toString();
}
