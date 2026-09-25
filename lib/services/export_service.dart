import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 导出文件的落盘策略。
///
/// - **桌面端（Windows / macOS / Linux）**：弹系统「另存为」对话框，由用户挑位置，
///   App 自己把文件写进去。
/// - **移动端（Android / iOS）**：写进临时目录后调起系统分享面板
///   （存到「文件」App、发微信 / QQ 等）。
///
/// 桌面端**不能**再用 `share_plus` 的 `shareXFiles`：
/// - Linux 上它直接抛 `UnimplementedError`；
/// - Windows 上它调的是面向商店应用的「共享」浮窗，国内环境里那个面板常常
///   一个可用目标都没有（要么空列表、要么根本不弹），用户看到的就是「点了没反应」；
/// - 老于 Windows 10 1809 的系统还会直接抛 `UnimplementedError`。
///
/// 桌面端「导出文件」正确的交互本来就是另存为对话框。
class ExportService {
  ExportService._();

  /// 是否是桌面端（Windows / macOS / Linux）。
  static bool get isDesktop =>
      !kIsWeb &&
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// 保存导出内容，返回最终文件路径；用户取消时返回 null。
  ///
  /// [bytes] 为文件内容，[fileName] 是「另存为」对话框里的默认文件名，
  /// [allowedExtensions] 用于过滤 + 补全后缀（如 `['csv']`）。
  static Future<String?> save({
    required String fileName,
    required List<int> bytes,
    required String dialogTitle,
    List<String>? allowedExtensions,
  }) async {
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

    if (isDesktop) {
      String? picked;
      var dialogBroken = false;
      try {
        picked = await FilePicker.platform.saveFile(
          dialogTitle: dialogTitle,
          fileName: fileName,
          initialDirectory: await _preferredDirectory(),
          type: (allowedExtensions == null || allowedExtensions.isEmpty)
              ? FileType.any
              : FileType.custom,
          allowedExtensions: allowedExtensions,
          // 让对话框挂在应用窗口上（Windows 下避免对话框跑到主窗口后面）
          lockParentWindow: true,
        );
      } catch (e) {
        // 极端情况：文件对话框起不来（插件异常等）。这时不能让导出彻底失败，
        // 退化成「直接写到『下载』目录」，只是没有让用户挑位置。
        debugPrint('[ExportService] 另存为对话框不可用，改为直接落盘：$e');
        dialogBroken = true;
      }

      if (!dialogBroken) {
        if (picked == null || picked.trim().isEmpty) return null; // 用户取消
        // Windows 的另存为对话框不保证补后缀（用户手改文件名时）
        final chosen = _ensureExtension(picked.trim(), allowedExtensions);
        await File(chosen).writeAsBytes(data, flush: true);
        return chosen;
      }

      final directory = await _preferredDirectory();
      final fallback = directory == null
          ? '${(await getTemporaryDirectory()).path}/$fileName'
          : '$directory/$fileName';
      final target = _ensureExtension(fallback, allowedExtensions);
      await File(target).writeAsBytes(data, flush: true);
      return target;
    }

    // 移动端：临时文件 + 系统分享面板
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(data, flush: true);
    await Share.shareXFiles([XFile(file.path)]);
    return file.path;
  }

  /// 在文件管理器里定位到刚导出的文件（尽力而为，失败返回 false）。
  static Future<bool> revealInFileManager(String path) async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer', <String>['/select,', path]);
        return true;
      }
      if (Platform.isMacOS) {
        await Process.run('open', <String>['-R', path]);
        return true;
      }
      if (Platform.isLinux) {
        await Process.run('xdg-open', <String>[File(path).parent.path]);
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// 「另存为」的起始目录：优先「下载」。
  static Future<String?> _preferredDirectory() async {
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null && await downloads.exists()) {
        return downloads.path;
      }
    } catch (_) {}
    try {
      final documents = await getApplicationDocumentsDirectory();
      if (await documents.exists()) return documents.path;
    } catch (_) {}
    return null;
  }

  static String _ensureExtension(String path, List<String>? extensions) {
    if (extensions == null || extensions.isEmpty) return path;
    final lower = path.toLowerCase();
    for (final ext in extensions) {
      if (lower.endsWith('.${ext.toLowerCase()}')) return path;
    }
    return '$path.${extensions.first}';
  }
}
