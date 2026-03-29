/// Slote rich text (AppFlowy-backed APIs; see `example/` for full editor UI).
library;

export 'src/appflowy/appflowy_document_controller.dart';
export 'src/appflowy/appflowy_editor_support.dart';
export 'src/appflowy/appflowy_undo_support.dart';
export 'src/appflowy/slote_inline_attributes.dart';
export 'src/appflowy/slote_delta_format.dart';
export 'src/appflowy/slote_format_toolbar_state.dart';
export 'src/appflowy/slote_format_drawers.dart';
export 'src/appflowy/slote_heading_support.dart';
export 'src/appflowy/slote_markdown_codec.dart';
export 'src/appflowy/slote_sup_sub_metrics.dart';
export 'src/appflowy/slote_text_span_decorator.dart';

/// Package id (for tests and diagnostics).
const String kRichTextPackageName = 'rich_text';
