import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// WebView / 平台视图的「静默失败」诊断。
///
/// ## 为什么需要它
///
/// Flutter 创建平台视图（macOS 上是 `AppKitView`）是**异步**的。失败时，
/// 引擎只在 `_DarwinViewState._createNewUiKitView` 里走一次
/// `FlutterError.reportError`，界面上什么都不显示 —— 组件会一直画一个空的
/// `SizedBox.expand()`。表现就是「网页一片空白、没有任何字、也没有任何报错」，
/// 单纯看界面完全无从下手（本项目在 v3.0.17 ~ v3.0.19 连续三版都被这条坑住）。
///
/// 这里做三件事：
///
/// 1. 接管 [FlutterError.onError] 与 [PlatformDispatcher.onError]，
///    把异常原样落到应用数据目录下的 `mood_tab_webview_diag.log`；
/// 2. 提供「看门狗」（[watch]）：某条网页在若干秒内一个加载回调都没收到时记一条；
/// 3. 把记录暴露给界面（[revision] / [report]），让用户能直接看到原因并复制。
class WebViewDiag {
  WebViewDiag._();

  /// 日志文件名（落在 `getApplicationDocumentsDirectory()` 下）。
  static const String fileName = 'mood_tab_webview_diag.log';

  /// 构建标记：**每改一次代码就换一次**。
  ///
  /// 会写在诊断日志的头部，用来确认「用户跑的到底是哪一份产物」——
  /// 本项目已经因为 macOS 上同时挂着好几个同名 DMG 而误判过两次
  /// （同名卷只差一个 ` 1` / ` 2` 后缀，用户又常常直接从挂载卷里跑）。
  /// 版本号没动的时候，这个标记就是唯一的区分手段。
  static const String buildTag = 'webviewfix-4';

  /// 内存里最多保留多少条，防止长时间运行越滚越大。
  static const int _maxLines = 200;

  /// 记录条数变化时自增，界面用它来刷新「诊断」入口。
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// 是否记录到**真正的故障**（平台视图没建出来 / 加载失败 / 超时无回调）。
  ///
  /// 只有它为 true 时界面才会顶出诊断入口 —— 否则每次正常加载都会亮红图标。
  static final ValueNotifier<bool> hasProblems = ValueNotifier<bool>(false);

  static final List<String> _lines = <String>[];
  static final List<String> _pending = <String>[];
  static File? _file;
  static bool _installed = false;

  static List<String> get lines => List<String>.unmodifiable(_lines);

  /// 有没有记录到东西。没有就说明一切正常，界面不必显示诊断入口。
  static bool get hasEntries => _lines.isNotEmpty;

  /// 日志文件路径；创建失败时为空串。
  static String get filePath => _file?.path ?? '';

  /// 全部记录，可直接复制给开发者。
  static String get report => _lines.join('\n');

  /// 安装诊断。必须在 `runApp` 之前调用，早于任何页面创建平台视图。
  ///
  /// 未 await 也不会丢记录：落盘前的内容先攒在内存里，文件就绪后一次性补写。
  static void install() {
    if (_installed) return;
    _installed = true;

    // 1) Flutter 框架错误。平台视图创建失败就是从这里溜走的。
    final FlutterExceptionHandler? previousHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      previousHandler?.call(details);
      final String message = details.exceptionAsString();
      final String context = details.context?.toDescription() ?? '';
      final String library = details.library ?? '';
      // ⚠️ 判据必须把**堆栈**也算进去。实测踩到的那条报错文字本身是
      //    `UnimplementedError: opaque is not implemented on macOS`，
      //    光看文字完全看不出跟网页有关；真正暴露身份的是堆栈里的
      //    `package:webview_flutter_wkwebview/...`。
      final String haystack = '$message $context $library ${details.stack ?? ''}';
      // UnimplementedError / UnsupportedError 一律当故障：它们只会来自
      // 「用到了某平台没实现的能力」，从来不是正常路径。
      final bool alwaysFatal =
          details.exception is UnimplementedError ||
          details.exception is UnsupportedError;
      if (alwaysFatal || _looksLikePlatformViewTrouble(haystack)) {
        problem(
          'FlutterError',
          message,
          stack: details.stack,
          context: context.isEmpty ? null : context,
          library: library.isEmpty ? null : library,
        );
      } else {
        record(
          'FlutterError',
          message,
          stack: details.stack,
          context: context.isEmpty ? null : context,
          library: library.isEmpty ? null : library,
        );
      }
    };

    // 2) 没人 await 的异步错误。
    final previousPlatformHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      final String message = '$error';
      if (_looksLikePlatformViewTrouble(message)) {
        problem('UncaughtError', message, stack: stack);
      } else {
        record('UncaughtError', message, stack: stack);
      }
      // 保持原有行为：原来没人接管就继续按「未捕获」处理，不悄悄吞掉。
      return previousPlatformHandler?.call(error, stack) ?? false;
    };

    // 3) 落盘。
    unawaited(_openFile());
  }

  /// 这段文本像不像「平台视图 / WebView 出问题」。
  ///
  /// [text] 由**报错文字 + context + library + 堆栈**拼成 ——
  /// 实测那条致命报错的文字是 `UnimplementedError: opaque is not implemented on macOS`，
  /// 只有堆栈里的 `package:webview_flutter_wkwebview/...` 才认得出是网页的问题。
  ///
  /// 框架把渲染溢出之类的良性问题也走 [FlutterError.onError]，
  /// 不加这层判断的话正常用一会儿就会到处顶红图标。
  static bool _looksLikePlatformViewTrouble(String text) {
    final String lower = text.toLowerCase();
    return lower.contains('platform view') ||
        lower.contains('platformview') ||
        lower.contains('appkitview') ||
        lower.contains('uikitview') ||
        lower.contains('webview') ||
        lower.contains('web_view') ||
        lower.contains('webview_flutter') ||
        lower.contains('createwithviewidentifier') ||
        lower.contains('creationparams') ||
        lower.contains('unimplemented') ||
        lower.contains(' is not implemented');
  }

  static Future<void> _openFile() async {
    try {
      final Directory dir = await getApplicationDocumentsDirectory();
      final File file = File(p.join(dir.path, fileName));
      await file.writeAsString(
        '脑电波 · WebView 诊断日志\n'
        'buildTag=$buildTag\n'
        'platform=${defaultTargetPlatform.name} '
        'isWeb=$kIsWeb '
        'debug=$kDebugMode\n'
        '----------------------------------------\n',
        mode: FileMode.write,
        flush: true,
      );
      _file = file;
      for (final String line in _pending) {
        await file.writeAsString(line, mode: FileMode.append, flush: true);
      }
      _pending.clear();
    } catch (e) {
      debugPrint('WebViewDiag: 无法创建诊断日志文件: $e');
    }
  }

  /// 记一条。
  static void record(
    String tag,
    String message, {
    StackTrace? stack,
    String? context,
    String? library,
  }) {
    final String now = _timestamp();
    final StringBuffer buffer = StringBuffer('[$now][$tag] $message');
    if (context != null && context.isNotEmpty) {
      buffer.write('\n    context: $context');
    }
    if (library != null && library.isNotEmpty) {
      buffer.write('\n    library: $library');
    }
    if (stack != null) {
      buffer.write('\n    ${stack.toString().trimRight()}');
    }
    final String line = buffer.toString();

    _lines.add(line);
    if (_lines.length > _maxLines) {
      _lines.removeRange(0, _lines.length - _maxLines);
    }
    debugPrint(line);

    final File? file = _file;
    if (file == null) {
      _pending.add('$line\n');
    } else {
      // 诊断日志不能反噬主流程：写失败就算了。
      file
          .writeAsString('$line\n', mode: FileMode.append, flush: true)
          .catchError((Object _) => file);
    }

    revision.value = revision.value + 1;
  }

  static String _timestamp() {
    final DateTime t = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    String three(int v) => v.toString().padLeft(3, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}'
        '.${three(t.millisecond)}';
  }

  /// 记一条**故障**。调用后界面上的诊断入口会亮起。
  static void problem(
    String tag,
    String message, {
    StackTrace? stack,
    String? context,
    String? library,
  }) {
    record(tag, '⚠️ $message', stack: stack, context: context, library: library);
    hasProblems.value = true;
  }

  /// 起一个看门狗。
  ///
  /// 平台视图创建失败时**一次回调都不会有**，界面上却完全静止，
  /// 所以「超时没有任何回调」本身就是一条重要线索。
  static WebViewWatchdog watch(
    String tag, {
    Duration timeout = const Duration(seconds: 8),
  }) => WebViewWatchdog._(tag, timeout);

  @visibleForTesting
  static void reset() {
    _lines.clear();
    _pending.clear();
    revision.value = 0;
    hasProblems.value = false;
  }
}

/// 单条网页的看门狗，见 [WebViewDiag.watch]。
class WebViewWatchdog {
  WebViewWatchdog._(this.tag, Duration timeout) {
    _timer = Timer(timeout, () {
      _timer = null;
      WebViewDiag.problem(
        tag,
        '打开 ${timeout.inSeconds} 秒后仍未收到任何加载回调'
        '（onPageFinished / onWebResourceError 都没来）'
        '—— 网页控件很可能根本没创建出来',
      );
    });
  }

  final String tag;
  Timer? _timer;

  /// 正常收到一个加载回调。
  void seen(String what) {
    _cancel();
    WebViewDiag.record(tag, what);
  }

  /// 加载明确失败了。
  void failed(String what) {
    _cancel();
    WebViewDiag.problem(tag, what);
  }

  void dispose() => _cancel();

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
