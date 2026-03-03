/// Italic formatting implementation
class ItalicFormatter {
  static const String marker = '*';

  static bool isItalic(String text, int position) {
    // Check if position is within italic markers
    // Implementation to be added
    return false;
  }

  static String apply(String text, int start, int end) {
    if (start < 0 || end > text.length || start >= end) return text;
    final selected = text.substring(start, end);
    final before = text.substring(0, start);
    final after = text.substring(end);
    return '$before$marker$selected$marker$after';
  }
}

