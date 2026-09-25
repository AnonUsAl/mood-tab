import 'dart:typed_data';

/// sfnt（TrueType / OpenType）字体文件的表目录解析。
///
/// 为什么需要它：`pdf` 包（`pw.Font.ttf(bytes)`）只认「**单个**、带 TrueType
/// 轮廓（`glyf` + `loca`）」的字体文件，它既不会解析 TTC 字体集合
/// （Windows 的 `msyh.ttc` 微软雅黑、macOS 的 `Songti.ttc` 都是这种格式），
/// 也不支持 CFF 轮廓的 OpenType（如 macOS 的 `PingFang.ttc`，表里根本没有
/// `glyf`，塞进去只会得到一份「没有字形」的 PDF）。
///
/// 本文件刻意只依赖 `dart:typed_data`，不引入 Flutter，方便脱离 App 单独验证。
///
/// 用法：把系统字体的原始字节交给 [extractPdfCompatibleFont]，
/// 拿到能直接喂给 `pw.Font.ttf()` 的字节；返回 null 表示这份字体不能用。

/// TTC（TrueType Collection）文件头魔数：'ttcf'
const int _ttcTag = 0x74746366;

/// 单个 TrueType 字体的 sfnt 版本号：0x00010000
const int _sfntTrueType = 0x00010000;

/// 老式 Mac TrueType 的 sfnt 版本号：'true'
const int _sfntVersionTrue = 0x74727565;

/// 字体必须带的表：pdf 包的 TtfParser 会断言前六个存在，
/// `glyf` / `loca` 则是「能画出字形」的前提（CFF 字体没有这两张表）。
const Set<String> _requiredTables = {
  'head',
  'name',
  'hmtx',
  'hhea',
  'cmap',
  'maxp',
  'glyf',
  'loca',
};

/// 一个 sfnt 字体的表目录。
class _SfntFace {
  _SfntFace({
    required this.version,
    required this.directoryOffset,
    required this.tables,
  });

  final int version;
  final int directoryOffset;
  final Map<String, _SfntTable> tables;

  /// 是否是一份 pdf 包能正确嵌入的字体：
  /// TrueType 轮廓 + 必需表齐全（OTTO/CFF 会被这里挡掉）。
  bool get isPdfCompatible {
    if (version != _sfntTrueType && version != _sfntVersionTrue) return false;
    for (final tag in _requiredTables) {
      if (!tables.containsKey(tag)) return false;
    }
    return true;
  }
}

class _SfntTable {
  _SfntTable({required this.offset, required this.length, required this.raw});

  final int offset;
  final int length;

  /// 表目录里的 16 字节原始条目（tag / checksum / offset / length），
  /// 提取时原样复制、只改写 offset 字段。
  final Uint8List raw;
}

/// 把 [data]（可能是 .ttf / .otf 单字体，也可能是 .ttc 字体集合）
/// 转成「单个、pdf 包可嵌入的 TrueType 字体」的字节。
///
/// 返回 null 表示这份文件里找不到可用的字体（CFF 轮廓、表缺失、文件损坏）。
Uint8List? extractPdfCompatibleFont(Uint8List data) {
  if (data.length < 16) return null;
  final view = ByteData.sublistView(data);

  if (view.getUint32(0) == _ttcTag) {
    // TTC：头部 tag(4) + version(4) + numFonts(4) + offsetTable[numFonts * 4]
    final numFonts = view.getUint32(8);
    if (numFonts == 0 || 12 + numFonts * 4 > data.length) return null;
    _SfntFace? best;
    var bestScore = -1000000;
    for (var i = 0; i < numFonts; i++) {
      final dirOffset = view.getUint32(12 + i * 4);
      final face = _readFace(data, dirOffset);
      if (face == null || !face.isPdfCompatible) continue;
      final score = _faceScore(_faceDisplayName(data, face));
      if (score > bestScore) {
        bestScore = score;
        best = face;
      }
    }
    if (best == null) return null;
    return _rebuild(data, best);
  }

  final face = _readFace(data, 0);
  if (face == null || !face.isPdfCompatible) return null;
  // 本来就是单字体文件，原样返回，不搬运表数据。
  return data;
}

/// 读取 [directoryOffset] 处的 sfnt 表目录。
_SfntFace? _readFace(Uint8List source, int directoryOffset) {
  final fileLength = source.length;
  if (directoryOffset < 0 || directoryOffset + 12 > fileLength) return null;
  final view = ByteData.sublistView(source);
  final version = view.getUint32(directoryOffset);
  final numTables = view.getUint16(directoryOffset + 4);
  if (numTables == 0) return null;
  if (directoryOffset + 12 + numTables * 16 > fileLength) return null;

  final tables = <String, _SfntTable>{};
  for (var i = 0; i < numTables; i++) {
    final entry = directoryOffset + 12 + i * 16;
    final tag = String.fromCharCodes(source.sublist(entry, entry + 4));
    final offset = view.getUint32(entry + 8);
    final length = view.getUint32(entry + 12);
    if (offset + length > fileLength) return null;
    tables[tag] = _SfntTable(
      offset: offset,
      length: length,
      raw: Uint8List.fromList(source.sublist(entry, entry + 16)),
    );
  }

  return _SfntFace(
    version: version,
    directoryOffset: directoryOffset,
    tables: tables,
  );
}

/// 把 TTC 里的某一个字体重建成独立的 sfnt 文件：
/// 新文件 = sfnt 头 + 表目录 + 各表的实际数据。
///
/// 注：各表的 checksum 字段保持原样，`head` 表的 checkSumAdjustment 因此不再
/// 准确，但 pdf 包解析时不校验 checksum，也不影响字形数据。
Uint8List? _rebuild(Uint8List source, _SfntFace face) {
  final tables = face.tables.values.toList();
  final headerSize = 12 + tables.length * 16;
  var totalSize = headerSize;
  for (final table in tables) {
    totalSize += _pad4(table.length);
  }

  final out = Uint8List(totalSize);
  final outView = ByteData.sublistView(out);
  // sfnt 头（sfntVersion / numTables / searchRange / entrySelector / rangeShift）
  out.setRange(0, 12, source, face.directoryOffset);

  var dataOffset = headerSize;
  for (var i = 0; i < tables.length; i++) {
    final table = tables[i];
    final entry = 12 + i * 16;
    out.setRange(entry, entry + 16, table.raw);
    outView.setUint32(entry + 8, dataOffset);
    out.setRange(dataOffset, dataOffset + table.length, source, table.offset);
    dataOffset += _pad4(table.length);
  }
  return out;
}

int _pad4(int value) => (value + 3) & ~3;

// ==================== 字体集合里「挑哪个 face」 ====================

/// 字体集合里各 face 的取舍打分。
///
/// 例子：macOS 的 `Songti.ttc` 里 0 号 face 是 `STSongti-SC-Black`
/// （特粗字重、只有 8159 个字形），6 号才是 `STSongti-SC-Regular`
/// （32965 个字形）。如果无脑取「第一个能用的」face，导出的 PDF 会又粗又缺字。
int _faceScore(String? name) {
  if (name == null || name.isEmpty) return 0;
  final n = name.toLowerCase();
  var score = 0;
  if (n.contains('sc')) score += 40; // 简体优先
  if (n.contains('tc')) score -= 20; // 繁体次之
  if (n.contains('regular') || n.contains('normal')) {
    score += 30;
  } else if (n.contains('medium')) {
    score += 20;
  } else if (n.contains('light')) {
    score += 10;
  }
  if (n.contains('black') || n.contains('heavy')) {
    score -= 40;
  } else if (n.contains('bold')) {
    score -= 30;
  }
  return score;
}

/// 取 face 的 PostScript 名（nameID 6），没有就退到全名（nameID 4）。
String? _faceDisplayName(Uint8List source, _SfntFace face) =>
    _readNameTableValue(source, face, 6) ??
    _readNameTableValue(source, face, 4);

/// 读 `name` 表里指定 nameID 的字符串（只做轻量解析，不碰字形数据）。
String? _readNameTableValue(Uint8List source, _SfntFace face, int wantedNameId) {
  final table = face.tables['name'];
  if (table == null) return null;
  final base = table.offset;
  if (base + 6 > source.length) return null;
  final view = ByteData.sublistView(source);
  final count = view.getUint16(base + 2);
  final stringOffset = base + view.getUint16(base + 4);
  String? fallback;

  for (var i = 0; i < count; i++) {
    // 记录：platformID(2) encodingID(2) languageID(2) nameID(2) length(2) offset(2)
    final record = base + 6 + i * 12;
    if (record + 12 > source.length) break;
    if (view.getUint16(record + 6) != wantedNameId) continue;
    final platformId = view.getUint16(record);
    final length = view.getUint16(record + 8);
    final start = stringOffset + view.getUint16(record + 10);
    if (start < 0 || length == 0 || start + length > source.length) continue;
    final raw = source.sublist(start, start + length);
    final value = platformId == 3
        ? _decodeUtf16Be(raw)
        : String.fromCharCodes(raw).replaceAll('\u0000', '');
    if (value.trim().isEmpty) continue;
    // Windows 平台（3）的记录最可靠，其余的留着兜底
    if (platformId == 3) return value;
    fallback ??= value;
  }
  return fallback;
}

String _decodeUtf16Be(Uint8List bytes) {
  final buffer = StringBuffer();
  for (var i = 0; i + 1 < bytes.length; i += 2) {
    buffer.writeCharCode((bytes[i] << 8) | bytes[i + 1]);
  }
  return buffer.toString();
}
