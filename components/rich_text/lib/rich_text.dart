/// Slote rich text (AppFlowy-backed APIs; see `example/` for full editor UI).
library;

export 'src/appflowy/appflowy_document_controller.dart';
export 'src/appflowy/appflowy_editor_support.dart';
export 'src/appflowy/appflowy_undo_support.dart';
export 'src/appflowy/slote_alignment_support.dart';
export 'src/appflowy/slote_inline_attributes.dart';
export 'src/appflowy/slote_delta_format.dart';
export 'src/appflowy/slote_caret_metrics.dart';
export 'src/appflowy/slote_end_of_paragraph_caret_height.dart';
export 'src/appflowy/slote_format_toolbar_state.dart';
export 'src/appflowy/slote_format_drawers.dart';
export 'src/appflowy/slote_block_component_builders.dart';
export 'src/appflowy/slote_heading_support.dart';
export 'src/appflowy/slote_outline.dart';
export 'src/appflowy/slote_markdown_codec.dart';
export 'src/appflowy/slote_sup_sub_metrics.dart';
export 'src/appflowy/slote_text_span_decorator.dart';
export 'src/ui/slote_toolbar_layout.dart';
export 'src/ui/slote_toolbar_vertical_page_physics.dart';

/// Package id (for tests and diagnostics).
const String kRichTextPackageName = 'rich_text';
