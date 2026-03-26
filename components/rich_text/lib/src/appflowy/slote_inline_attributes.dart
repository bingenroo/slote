/// Slote-defined inline attribute keys stored in AppFlowy delta attributes.
///
/// These are intentionally *not* part of `AppFlowyRichTextKeys` (package-owned).
library;

/// Inline superscript attribute key.
///
/// Value convention: `true` when enabled, `null`/absent when cleared.
const String kSloteSuperscriptAttribute = 'slote_superscript';

/// Inline subscript attribute key.
///
/// Value convention: `true` when enabled, `null`/absent when cleared.
const String kSloteSubscriptAttribute = 'slote_subscript';

