import 'dart:async';
import 'dart:convert';

import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:rich_text/rich_text.dart';
import 'package:shared/shared.dart';
import 'package:slote/src/services/local_db.dart';
import 'package:slote/src/model/note.dart';
import 'package:slote/src/services/slote_rich_text_storage.dart';
import 'package:theme/theme.dart';

class CreateNoteView extends StatefulWidget {
  const CreateNoteView({super.key, this.note});

  final Note? note;

  @override
  State<CreateNoteView> createState() => _CreateNoteViewState();
}

class _CreateNoteViewState extends State<CreateNoteView> {
  final _titleController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<SloteRichTextEditorScaffoldState> _editorShellKey =
      GlobalKey<SloteRichTextEditorScaffoldState>();

  final LocalDBService _localDb = LocalDBService();

  Note? _currentNote;

  late final RichTextEditorController _richTextController;

  List<SloteOutlineEntry> _outline = const [];

  // Cached state used by the persistence layer (so back navigation can flush).
  String _latestBodyJsonString = sloteEmptyDocumentJsonString();
  late String _latestDrawingJsonString;
  Timer? _titleSaveDebounceTimer;

  late final DrawController _drawController;
  bool _isDrawingMode = true;

  /// Document → canvas local for ink. Wave G: mutate in place or copy from
  /// `ZoomPanSurface.onTransformChanged` (and rebuild).
  final Matrix4 _drawingDocumentTransform = Matrix4.identity();

  /// In-progress stroke or eraser drag. Wave G: pass to viewport `isDrawingActive`.
  // ignore: unused_field
  bool _isDrawingActive = false;

  bool _suppressSaves = false;
  bool _saveAgain = false;
  Future<void>? _activeSaveLoop;

  static const Duration _kTitleSaveDebounce = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.note?.title ?? '';

    _currentNote = widget.note;
    _latestBodyJsonString = widget.note == null
        ? sloteEmptyDocumentJsonString()
        : normalizeNoteBodyToDocumentJsonString(widget.note!.body);

    final initialJson = widget.note != null
        ? parseAppFlowyDocumentJsonOrEmpty(widget.note!.body)
        : Map<String, dynamic>.from(kSloteEmptyDocumentJson);

    _richTextController = RichTextEditorController.fromJson(
      initialJson,
      onDocumentJsonChanged: (json) {
        // `onDocumentJsonChanged` is already debounced by the controller.
        _latestBodyJsonString =
            normalizeNoteBodyToDocumentJsonString(jsonEncode(json));
        _requestSave();
      },
      onDebouncedDocumentChanged: _refreshOutline,
    );

    _drawController = DrawController();
    _hydrateDrawingFromNote();
    _latestDrawingJsonString = jsonEncode(_drawController.toJson());
    _drawController.addListener(_onDrawingChanged);

    _titleController.addListener(_onTitleChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshOutline();
    });
  }

  void _refreshOutline() {
    if (!mounted) return;
    final next = sloteCollectOutlineEntries(
      _richTextController.editorState.document,
    );
    setState(() => _outline = next);
  }

  void _hydrateDrawingFromNote() {
    final raw = widget.note?.drawingData;
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _drawController.fromJson(decoded);
      }
    } catch (_) {
      // Ignore legacy or corrupt drawing payloads.
    }
  }

  void _onDrawingChanged() {
    _latestDrawingJsonString = jsonEncode(_drawController.toJson());
    _requestSave();
  }

  static const double _kOutlineWideBreakpoint = 600;

  @override
  void dispose() {
    _suppressSaves = true;
    _titleSaveDebounceTimer?.cancel();
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _drawController.removeListener(_onDrawingChanged);
    _drawController.dispose();
    _richTextController.dispose();
    super.dispose();
  }

  void _handleBackNavigation() {
    if (!mounted) return;
    unawaited(_handleBackNavigationAsync());
  }

  Future<void> _handleBackNavigationAsync() async {
    await _flushLatestToDb();
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _onTitleChanged() {
    // Debounce title writes separately from rich-text writes.
    _titleSaveDebounceTimer?.cancel();
    _titleSaveDebounceTimer = Timer(_kTitleSaveDebounce, () {
      _requestSave();
    });
  }

  void _requestSave() {
    if (_suppressSaves || !mounted) return;
    _saveAgain = true;
    _activeSaveLoop ??= _saveLoop();
  }

  Future<void> _flushLatestToDb() async {
    if (_suppressSaves || !mounted) return;
    _saveAgain = true;
    _activeSaveLoop ??= _saveLoop();
    await _activeSaveLoop;
  }

  Future<void> _saveLoop() async {
    try {
      while (_saveAgain && !_suppressSaves) {
        _saveAgain = false;
        await _saveOnce();
      }
    } finally {
      _activeSaveLoop = null;
    }
  }

  Future<void> _saveOnce() async {
    if (_suppressSaves) return;

    final title = _titleController.text;
    final bodyJsonString = _latestBodyJsonString;

    final titleTrimmed = title.trim();
    final previewTrimmed =
        plainTextPreviewFromDocumentJsonString(bodyJsonString).trim();
    final hasMeaningfulContent =
        titleTrimmed.isNotEmpty || previewTrimmed.isNotEmpty;
    final hasDrawing = _drawController.strokes.isNotEmpty;

    // For new notes, don't create a record until we have user content.
    if (_currentNote == null && !hasMeaningfulContent && !hasDrawing) return;

    final now = DateTime.now();

    if (_currentNote != null) {
      // Avoid unnecessary writes when nothing changed.
      if (_currentNote!.title == title &&
          _currentNote!.body == bodyJsonString &&
          _currentNote!.drawingData == _latestDrawingJsonString) {
        return;
      }
      _currentNote = _currentNote!.copyWith(
        title: title,
        body: bodyJsonString,
        drawingData: _latestDrawingJsonString,
        lastMod: now,
      );
    } else {
      _currentNote = Note(
        id: DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF,
        title: title,
        body: bodyJsonString,
        drawingData: _latestDrawingJsonString,
        lastMod: now,
      );
    }

    await _localDb.saveNote(note: _currentNote!);
  }

  Future<void> _confirmDelete() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            widget.note == null ? 'Discard?' : 'Close note?',
            style: GoogleFonts.poppins(fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Lottie.asset(AnimationAssets.delete),
              Text(
                widget.note == null
                    ? 'Leave this screen? Nothing is saved yet.'
                    : 'Leave this screen? Changes are saved to the database.',
                style: GoogleFonts.poppins(fontSize: 15),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (widget.note == null && _currentNote != null) {
                  // Discard a newly-created draft by deleting it from DB.
                  _suppressSaves = true;
                  final activeSaveLoop = _activeSaveLoop;
                  if (activeSaveLoop != null) {
                    await activeSaveLoop;
                  }
                  await _localDb.deleteNote(id: _currentNote!.id);
                  _currentNote = null;
                }
                if (mounted) Navigator.pop(this.context);
              },
              child: const Text('Proceed'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final outlineTitle = GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w600,
    );
    final outlineEmpty = GoogleFonts.poppins(
      fontSize: 15,
      color: Theme.of(context).hintColor,
    );
    final outlineEntry = GoogleFonts.poppins(fontSize: 15);

    return SloteRichTextEditorScaffold(
      key: _editorShellKey,
      scaffoldKey: _scaffoldKey,
      controller: _richTextController,
      outline: _outline,
      outlineWideBreakpoint: _kOutlineWideBreakpoint,
      editorStyleBreakpoint: 600,
      toolbarLayout: SloteToolbarLayout.verticalScroll,
      outlineTitleTextStyle: outlineTitle,
      outlineEmptyTextStyle: outlineEmpty,
      outlineEntryTextStyle: outlineEntry,
      bodyFooter: SizedBox(
        height: 300,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          child: SloteDrawScaffold(
            controller: _drawController,
            isDrawingMode: _isDrawingMode,
            documentTransform: _drawingDocumentTransform,
            onStrokeCaptureActiveChanged: (active) {
              setState(() => _isDrawingActive = active);
            },
            selectedToolColor: scheme.primary,
            selectedColorBorderColor: scheme.primary,
          ),
        ),
      ),
      appBar: AppBar(
        toolbarHeight: 52,
        leading: IconButton(
          onPressed: _handleBackNavigation,
          icon: FaIcon(
            FontAwesomeIcons.arrowLeft,
            size: 20,
            color: scheme.onPrimary,
          ),
        ),
        title: TextField(
          controller: _titleController,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'New Slote',
            hintStyle: TextStyle(
              color: scheme.onPrimary.withValues(alpha: 0.6),
            ),
          ),
          style: GoogleFonts.poppins(
            fontSize: AppThemeConfig.titleFontSize,
            color: scheme.onPrimary,
            decorationColor: scheme.onPrimary,
          ),
          cursorColor: scheme.onPrimary,
        ),
        actions: [
          IconButton(
            icon: FaIcon(
              _isDrawingMode
                  ? FontAwesomeIcons.pen
                  : FontAwesomeIcons.eye,
              size: 18,
              color: scheme.onPrimary,
            ),
            onPressed: () {
              setState(() => _isDrawingMode = !_isDrawingMode);
            },
            tooltip: _isDrawingMode ? 'Drawing on' : 'Drawing off (view)',
          ),
          IconButton(
            icon: FaIcon(
              FontAwesomeIcons.listUl,
              size: 18,
              color: scheme.onPrimary,
            ),
            onPressed: () => _editorShellKey.currentState?.showOutline(),
            tooltip: 'Outline',
          ),
          IconButton(
            icon: FaIcon(
              FontAwesomeIcons.trash,
              size: 18,
              color: scheme.onPrimary,
            ),
            onPressed: _confirmDelete,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}
