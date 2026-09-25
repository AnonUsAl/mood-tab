/// 隐私锁 PIN 码的位数
const int kPinLength = 4;

/// 把任意输入规范化为「不超过 [kPinLength] 位、只含半角数字」的字符串。
///
/// - 全角数字 ０-９（U+FF10–U+FF19）→ 半角 0-9
/// - 丢弃空格、零宽字符、标点等一切非数字
/// - 截断到 [kPinLength] 位
///
/// 存在的意义：中文输入法全角模式下敲出来的是全角数字，而
/// `FilteringTextInputFormatter.digitsOnly` 会把它们**静默丢弃**；
/// 历史版本也可能把这类脏值写进过 `shared_preferences`。
/// 统一走这个函数，才能保证「存进去的」和「比对时输入的」是同一套字符。
String normalizePinInput(String raw) {
  final StringBuffer buffer = StringBuffer();
  for (final int rune in raw.runes) {
    int code = rune;
    if (code >= 0xFF10 && code <= 0xFF19) {
      code -= 0xFF10 - 0x30;
    }
    if (code < 0x30 || code > 0x39) continue;
    buffer.writeCharCode(code);
    if (buffer.length >= kPinLength) break;
  }
  return buffer.toString();
}

/// 该 PIN 是不是一个「能用来上锁」的合法值（规范化后正好 [kPinLength] 位）
bool isValidPin(String raw) =>
    normalizePinInput(raw).length == kPinLength;
