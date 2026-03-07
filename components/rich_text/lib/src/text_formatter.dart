/// Text formatting utilities
class TextFormatter {
  /// Apply bold formatting to selected text
  static String applyBold(String text, int start, int end) {
    if (start < 0 || end > text.length || start >= end) return text;
    final selected = text.substring(start, end);
    final before = text.substring(0, start);
    final after = text.substring(end);
    return '$before**$selected**$after';
  }

  /// Apply italic formatting to selected text
  static String applyItalic(String text, int start, int end) {
    if (start < 0 || end > text.length || start >= end) return text;
    final selected = text.substring(start, end);
    final before = text.substring(0, start);
    final after = text.substring(end);
    return '$before*$selected*$after';
  }

  /// Apply underline formatting to selected text
  static String applyUnderline(String text, int start, int end) {
    if (start < 0 || end > text.length || start >= end) return text;
    final selected = text.substring(start, end);
    final before = text.substring(0, start);
    final after = text.substring(end);
    return '${before}__${selected}__$after';
  }
}

