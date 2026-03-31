import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

mixin BlockComponentAlignMixin {
  Node get node;

  Alignment? get alignment {
    final alignString = node.attributes[blockComponentAlign] as String?;
    switch (alignString) {
      case 'center':
        return Alignment.center;
      case 'right':
        return Alignment.centerRight;
      case 'left':
        return Alignment.centerLeft;
      case 'justify':
        // Visual block anchor matches left; word spacing uses [TextAlign.justify]
        // via [effectiveBlockTextAlign].
        return Alignment.centerLeft;
      default:
        return null;
    }
  }

  /// Resolves [RichText.textAlign] from [blockComponentAlign], including
  /// `justify` which cannot be represented by [Alignment] alone.
  TextAlign effectiveBlockTextAlign(TextAlign fallback) {
    final alignString = node.attributes[blockComponentAlign] as String?;
    if (alignString == 'justify') {
      return TextAlign.justify;
    }
    return alignment?.toTextAlign ?? fallback;
  }
}
