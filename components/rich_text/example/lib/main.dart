import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'app.dart';

/// Entry for the AppFlowy rich-text spike — see [RichTextEditorApp].
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  editorLaunchUrl = (href) async {
    if (href == null || href.isEmpty) return false;
    final trimmed = href.trim();
    final uri = Uri.tryParse(trimmed);
    final target = (uri != null && uri.hasScheme) ? trimmed : 'https://$trimmed';
    try {
      return launchUrlString(
        target,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  };
  runApp(const RichTextEditorApp());
}
