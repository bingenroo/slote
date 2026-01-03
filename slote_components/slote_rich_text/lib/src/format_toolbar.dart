import 'package:flutter/material.dart';

/// Format toolbar for rich text editing
class FormatToolbar extends StatelessWidget {
  final VoidCallback? onBold;
  final VoidCallback? onItalic;
  final VoidCallback? onUnderline;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;

  const FormatToolbar({
    super.key,
    this.onBold,
    this.onItalic,
    this.onUnderline,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.format_bold, color: isBold ? Colors.blue : null),
          onPressed: onBold,
          tooltip: 'Bold',
        ),
        IconButton(
          icon: Icon(Icons.format_italic, color: isItalic ? Colors.blue : null),
          onPressed: onItalic,
          tooltip: 'Italic',
        ),
        IconButton(
          icon: Icon(Icons.format_underlined,
              color: isUnderline ? Colors.blue : null),
          onPressed: onUnderline,
          tooltip: 'Underline',
        ),
      ],
    );
  }
}

