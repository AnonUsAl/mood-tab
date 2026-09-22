import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 桌面端数据库工厂初始化（有 dart:io 的平台使用本实现）。
///
/// `sqflite` 本体只实现了 Android / iOS / macOS，
/// Windows 与 Linux 上 `databaseFactory` 没有被任何插件设置过，
/// 直接调用 `openDatabase` 会抛 "databaseFactory not initialized"，
/// 表现为「页面全空、记录也存不进去」。
///
/// 这两个平台需要切到 sqflite 的 FFI 实现。
/// 原生 sqlite3 库由 package:sqlite3 的 code asset 在构建时自动打进应用包，
/// 不需要手动往 exe 旁边放 sqlite3.dll。
///
/// 其他平台（Android / iOS / macOS）保持原生实现，这里什么都不做。
void initDesktopDatabaseFactory() {
  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
