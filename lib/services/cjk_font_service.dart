import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../utils/ttc_font.dart';

/// 给「导出 PDF」找一份能画中文的字体。
///
/// 查找顺序：
/// 1. 磁盘缓存（只缓存联网下回来的字体）
/// 2. **系统自带中文字体**——离线可用、字库完整，所以优先于联网
/// 3. 联网下载 Noto Sans SC（老逻辑，保留作兜底）
///
/// 早先只做了第 3 步，而 `fonts.googleapis.com` 在国内取不到，兜底的 `catch`
/// 又把异常吞掉 → 导出的 PDF 里所有中文都是空白，看着就像「导出不可用」。
class CjkFontService {
  CjkFontService._();

  static const String _cacheFileName = 'cjk_font.ttf';
  static const Duration _networkTimeout = Duration(seconds: 12);

  static ByteData? _memoryCache;

  /// 取可用于 PDF 的中文字体；全部失败返回 null（PDF 会退化成内置西文字体）。
  static Future<ByteData?> load() async {
    final cached = _memoryCache;
    if (cached != null) return cached;

    final fromDisk = await _readCache();
    if (fromDisk != null) return _memoryCache = fromDisk;

    final fromSystem = await _loadSystemFont();
    if (fromSystem != null) return _memoryCache = fromSystem;

    final downloaded = await _downloadFont();
    if (downloaded != null) {
      await _writeCache(downloaded);
      return _memoryCache = downloaded;
    }

    return null;
  }

  // ==================== 系统字体 ====================

  static List<String> get _systemFontCandidates {
    if (Platform.isWindows) {
      // 用 %WINDIR% 而不是写死 C:\Windows（系统盘不一定是 C）
      final winDir = Platform.environment['WINDIR'] ?? r'C:\Windows';
      return <String>[
        '$winDir\\Fonts\\msyh.ttc', // 微软雅黑
        '$winDir\\Fonts\\simhei.ttf', // 黑体
        '$winDir\\Fonts\\simsun.ttc', // 宋体
        '$winDir\\Fonts\\Deng.ttf', // 等线
        '$winDir\\Fonts\\simkai.ttf', // 楷体
        '$winDir\\Fonts\\simfang.ttf', // 仿宋
        '$winDir\\Fonts\\msjh.ttc', // 微软正黑（繁体版系统）
      ];
    }
    if (Platform.isMacOS) {
      return const <String>[
        '/System/Library/Fonts/Supplemental/Songti.ttc', // 宋体
        '/System/Library/Fonts/STHeiti Light.ttc', // 黑体
        '/Library/Fonts/Arial Unicode.ttf',
        '/System/Library/Fonts/Hiragino Sans GB.ttc',
        '/System/Library/Fonts/PingFang.ttc',
      ];
    }
    if (Platform.isLinux) {
      return const <String>[
        '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',
        '/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc',
        '/usr/share/fonts/truetype/wqy/wqy-microhei.ttc',
        '/usr/share/fonts/truetype/arphic/uming.ttc',
      ];
    }
    return const <String>[];
  }

  static Future<ByteData?> _loadSystemFont() async {
    for (final path in _systemFontCandidates) {
      try {
        final file = File(path);
        if (!await file.exists()) continue;
        final usable = extractPdfCompatibleFont(await file.readAsBytes());
        if (usable == null) continue; // CFF 轮廓 / 表缺失 → 换下一个
        debugPrint('[CjkFontService] 使用系统字体：$path');
        return ByteData.sublistView(usable);
      } catch (e) {
        debugPrint('[CjkFontService] 读取系统字体失败 $path：$e');
      }
    }
    return null;
  }

  // ==================== 磁盘缓存 ====================

  static Future<File?> _cacheFile() async {
    try {
      final dir = await getApplicationSupportDirectory();
      return File('${dir.path}/$_cacheFileName');
    } catch (_) {
      return null;
    }
  }

  static Future<ByteData?> _readCache() async {
    try {
      final file = await _cacheFile();
      if (file == null || !await file.exists()) return null;
      final usable = extractPdfCompatibleFont(await file.readAsBytes());
      if (usable == null) return null; // 旧缓存坏了，忽略
      debugPrint('[CjkFontService] 使用缓存字体：${file.path}');
      return ByteData.sublistView(usable);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeCache(ByteData font) async {
    try {
      final file = await _cacheFile();
      if (file == null) return;
      await file.writeAsBytes(
        font.buffer.asUint8List(font.offsetInBytes, font.lengthInBytes),
        flush: true,
      );
    } catch (_) {
      // 缓存写失败不影响本次导出
    }
  }

  // ==================== 联网兜底 ====================

  static const List<String> _fontCssUrls = <String>[
    'https://fonts.googleapis.com/css2?family=Noto+Sans+SC:wght@400',
    // 国内可达的 Google Fonts 镜像，作为同源替代
    'https://fonts.loli.net/css2?family=Noto+Sans+SC:wght@400',
  ];

  static Future<ByteData?> _downloadFont() async {
    for (final cssUrl in _fontCssUrls) {
      try {
        final css = await http.get(Uri.parse(cssUrl)).timeout(_networkTimeout);
        if (css.statusCode != 200) continue;
        final match =
            RegExp(r'url\(([^)]+)\)').firstMatch(css.body);
        if (match == null) continue;
        var fontUrl = match.group(1)!.trim().replaceAll('"', '');
        if (fontUrl.startsWith('//')) fontUrl = 'https:$fontUrl';
        final res =
            await http.get(Uri.parse(fontUrl)).timeout(_networkTimeout);
        if (res.statusCode != 200) continue;
        // 下载回来的必须是 PDF 包能嵌入的 TrueType（woff2 会被这里挡掉）
        final usable = extractPdfCompatibleFont(res.bodyBytes);
        if (usable == null) continue;
        debugPrint('[CjkFontService] 已下载字体：$fontUrl');
        return ByteData.sublistView(usable);
      } catch (e) {
        debugPrint('[CjkFontService] 下载字体失败 $cssUrl：$e');
      }
    }
    return null;
  }
}
