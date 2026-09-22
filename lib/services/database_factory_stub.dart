/// 无 dart:io 平台（Web）上的空实现。
///
/// 这里刻意不 import `package:sqflite_common_ffi/sqflite_ffi.dart`
/// —— 它依赖 dart:ffi，在 Web 构建里会直接编译失败。
/// 条件导入（见 `database_service.dart`）保证只有原生平台会用到真实实现。
void initDesktopDatabaseFactory() {}
