import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/editor/editor_component/service/ime/delta_input_on_floating_cursor_update.dart';
import 'package:appflowy_editor/src/editor/util/platform_extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'ime/delta_input_impl.dart';

// handle software keyboard and hardware keyboard
class KeyboardServiceWidget extends StatefulWidget {
  const KeyboardServiceWidget({
    super.key,
    this.commandShortcutEvents = const [],
    this.characterShortcutEvents = const [],
    this.focusNode,
    this.contentInsertionConfiguration,
    required this.child,
  });

  final ContentInsertionConfiguration? contentInsertionConfiguration;
  final FocusNode? focusNode;
  final List<CommandShortcutEvent> commandShortcutEvents;
  final List<CharacterShortcutEvent> characterShortcutEvents;
  final Widget child;

  @override
  State<KeyboardServiceWidget> createState() => KeyboardServiceWidgetState();
}

@visibleForTesting
class KeyboardServiceWidgetState extends State<KeyboardServiceWidget>
    implements AppFlowyKeyboardService {
  late final SelectionGestureInterceptor interceptor;
  late final EditorState editorState;
  late final TextInputService textInputService;
  late final FocusNode focusNode;

  final List<AppFlowyKeyboardServiceInterceptor> interceptors = [];

  // previous selection
  Selection? previousSelection;

  // use for IME only
  bool enableIMEShortcuts = true;

  // use for hardware keyboard only
  bool enableKeyboardShortcuts = true;

  @override
  void initState() {
    super.initState();

    editorState = Provider.of<EditorState>(context, listen: false);
    editorState.selectionNotifier.addListener(_onSelectionChanged);

    interceptor = SelectionGestureInterceptor(
      key: 'keyboard',
      canTap: (details) {
        enableIMEShortcuts = true;
        focusNode.requestFocus();
        textInputService.close();
        return true;
      },
    );
    editorState.service.selectionService
        .registerGestureInterceptor(interceptor);

    textInputService = buildTextInputService();

    focusNode = widget.focusNode ?? FocusNode(debugLabel: 'keyboard service');
    focusNode.addListener(_onFocusChanged);

    keepEditorFocusNotifier.addListener(_onKeepEditorFocusChanged);
  }

  @override
  void dispose() {
    editorState.selectionNotifier.removeListener(_onSelectionChanged);
    editorState.service.selectionService.unregisterGestureInterceptor(
      'keyboard',
    );
    focusNode.removeListener(_onFocusChanged);
    if (widget.focusNode == null) {
      focusNode.dispose();
    }
    keepEditorFocusNotifier.removeListener(_onKeepEditorFocusChanged);
    super.dispose();
  }

  @override
  void disable({
    bool showCursor = false,
    UnfocusDisposition disposition = UnfocusDisposition.previouslyFocusedChild,
  }) {
    focusNode.unfocus(disposition: disposition);
  }

  @override
  void enable() {
    focusNode.requestFocus();
  }

  @override
  void enableShortcuts() {
    enableKeyboardShortcuts = true;
  }

  @override
  void disableShortcuts() {
    enableKeyboardShortcuts = false;
  }

  // Used in mobile only
  @override
  void closeKeyboard() {
    textInputService.close();
  }

  // Used in mobile only
  @override
  void enableKeyBoard(Selection selection) {
    _attachTextInputService(selection);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;
    // if there is no command shortcut event, we don't need to handle hardware keyboard.
    // like in read-only mode.
    if (widget.commandShortcutEvents.isNotEmpty) {
      // the Focus widget is used to handle hardware keyboard.
      child = Focus(
        focusNode: focusNode,
        onKeyEvent: _onKeyEvent,
        child: child,
      );
    }

    // ignore the default behavior of the space key on web
    if (kIsWeb) {
      child = Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.space):
              const DoNothingAndStopPropagationIntent(),
        },
        child: child,
      );
    }

    return child;
  }

  @override
  void registerInterceptor(AppFlowyKeyboardServiceInterceptor interceptor) {
    interceptors.add(interceptor);
  }

  @override
  void unregisterInterceptor(AppFlowyKeyboardServiceInterceptor interceptor) {
    interceptors.remove(interceptor);
  }

  /// handle hardware keyboard
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (!enableKeyboardShortcuts) {
      return KeyEventResult.ignored;
    }

    if ((event is! KeyDownEvent && event is! KeyRepeatEvent) ||
        !enableIMEShortcuts) {
      if (textInputService.composingTextRange != TextRange.empty) {
        return KeyEventResult.skipRemainingHandlers;
      }
      return KeyEventResult.ignored;
    }

    for (final shortcutEvent in widget.commandShortcutEvents) {
      // check if the shortcut event can respond to the raw key event
      if (shortcutEvent.canRespondToRawKeyEvent(event)) {
        final result = shortcutEvent.handler(editorState);
        if (result == KeyEventResult.handled) {
          AppFlowyEditorLog.keyboard.debug(
            'keyboard service - handled by command shortcut event: $shortcutEvent',
          );
          return KeyEventResult.handled;
        } else if (result == KeyEventResult.skipRemainingHandlers) {
          AppFlowyEditorLog.keyboard.debug(
            'keyboard service - skip by command shortcut event: $shortcutEvent',
          );
          return KeyEventResult.skipRemainingHandlers;
        }
        continue;
      }
    }

    return KeyEventResult.ignored;
  }

  void _onSelectionChanged() {
    final doNotAttach = editorState
        .selectionExtraInfo?[selectionExtraInfoDoNotAttachTextService];
    if (doNotAttach == true) {
      return;
    }

    // attach the delta text input service if needed
    final selection = editorState.selection;

    enableIMEShortcuts = true;

    if (selection == null) {
      textInputService.close();
    } else {
      // For the deletion, we should attach the text input service immediately.
      _attachTextInputService(selection);
      _updateCaretPosition(selection);

      if (editorState.selectionUpdateReason == SelectionUpdateReason.uiEvent) {
        focusNode.requestFocus();
        AppFlowyEditorLog.editor.debug('keyboard service - request focus');
      } else {
        AppFlowyEditorLog.editor.debug(
          'keyboard service - selection changed: $selection',
        );
      }
    }

    previousSelection = selection;
  }

  /// Plain text of the nearest **non-empty** block before [path], skipping empty
  /// paragraphs (e.g. blank lines from repeated Enter). Android may still hold
  /// that block's text in the IME when the cursor sits below one or more empty
  /// blocks; comparing only the immediate [path.previous] misses that and lets
  /// ghost deltas through (caret jumps / typing stuck after 2+ line breaks).
  String _nearestNonEmptyPrecedingPlain(Path path) {
    var walk = path.previous;
    for (var i = 0; i < 64; i++) {
      final n = editorState.getNodeAtPath(walk);
      final p = n?.delta?.toPlainText() ?? '';
      if (p.isNotEmpty) {
        return p;
      }
      final next = walk.previous;
      if (next.equals(walk)) {
        break;
      }
      walk = next;
    }
    return '';
  }

  /// Android often echoes the **previous** block's buffer after Enter splits
  /// the document; applying that delta jumps the caret back (see SLOTE-IME logs).
  bool _shouldApplyAndroidImeUpdate(TextEditingValue pu) {
    final sel = editorState.selection;
    if (sel == null || !sel.isCollapsed) {
      return true;
    }
    final path = sel.start.path;
    if (path.isEmpty || path.last <= 0) {
      return true;
    }

    final prevPlain = _nearestNonEmptyPrecedingPlain(path);
    if (prevPlain.isEmpty) {
      return true;
    }

    final node = editorState.getNodeAtPath(path);
    final delta = node?.delta;
    if (delta == null) {
      return true;
    }

    final plainLen = delta.toPlainText().length;
    if (plainLen > 0) {
      return true;
    }

    if (pu.text.isEmpty) {
      return true;
    }

    final imeText = pu.text;
    final matchesPrev = imeText == prevPlain || imeText == '$prevPlain\n';
    if (!matchesPrev) {
      return true;
    }

    final extent = pu.selection.extentOffset;
    if (extent >= prevPlain.length) {
      final msg =
          'SLOTE-IME filter: REJECT ghost buffer path=$path '
          'prevLen=${prevPlain.length} imeLen=${imeText.length} extent=$extent';
      AppFlowyEditorLog.input.warn(msg);
      // debugPrint(msg);
      return false;
    }
    return true;
  }

  void _attachTextInputService(Selection selection) {
    final textEditingValue = _getCurrentTextEditingValue(selection);
    AppFlowyEditorLog.editor.debug(
      'keyboard service - attach text input service: $textEditingValue',
    );
    if (textEditingValue != null) {
      textInputService.attach(
        textEditingValue,
        TextInputConfiguration(
          viewId: View.of(context).viewId,
          enableDeltaModel: false,
          inputType: TextInputType.multiline,
          textCapitalization: TextCapitalization.none,
          inputAction: TextInputAction.newline,
          keyboardAppearance: Theme.of(context).brightness,
          allowedMimeTypes:
              widget.contentInsertionConfiguration?.allowedMimeTypes ?? [],
        ),
      );
      // disable shortcuts when the IME active
      enableIMEShortcuts = textEditingValue.composing == TextRange.empty;
    } else {
      enableIMEShortcuts = true;
    }
  }

  // This function is used to get the current text editing value of the editor
  // based on the given selection.
  TextEditingValue? _getCurrentTextEditingValue(Selection selection) {
    // Get all the editable nodes in the selection.
    final editableNodes = editorState
        .getNodesInSelection(selection)
        .where((element) => element.delta != null);

    // if the selection is inline and the selection is updated by ui event,
    // we should clear the composing range on Android.
    final shouldClearComposingRange =
        editorState.selectionType == SelectionType.inline &&
            editorState.selectionUpdateReason == SelectionUpdateReason.uiEvent;

    if (PlatformExtension.isAndroid && shouldClearComposingRange) {
      textInputService.clearComposingTextRange();
    }

    // Get the composing text range.
    final composingTextRange =
        textInputService.composingTextRange ?? TextRange.empty;
    if (editableNodes.isNotEmpty) {
      // Get the text by concatenating all the editable nodes in the selection.
      var text = editableNodes.fold<String>(
        '',
        (sum, editableNode) => '$sum${editableNode.delta!.toPlainText()}\n',
      );

      // Remove the last '\n'.
      text = text.substring(0, text.length - 1);

      // The editor's selection offsets are in document delta space, which can
      // temporarily drift from plainText length around block-splitting (Enter).
      // If we send an invalid selection to the platform IME, Android may stop
      // accepting further edits after the first character.
      final base = selection.startIndex.clamp(0, text.length);
      final extent = selection.endIndex.clamp(0, text.length);

      return TextEditingValue(
        text: text,
        selection: TextSelection(
          baseOffset: base,
          extentOffset: extent,
        ),
        composing: composingTextRange,
      );
    }
    return null;
  }

  void _onFocusChanged() {
    AppFlowyEditorLog.editor.debug(
      'keyboard service - focus changed: ${focusNode.hasFocus}}',
    );

    /// On web, we don't need to close the keyboard when the focus is lost.
    if (kIsWeb) {
      return;
    }

    // clear the selection when the focus is lost.
    if (!focusNode.hasFocus) {
      if (keepEditorFocusNotifier.shouldKeepFocus) {
        return;
      }

      final children =
          WidgetsBinding.instance.focusManager.primaryFocus?.children;
      if (children != null && !children.contains(focusNode)) {
        editorState.selection = null;
      }
      textInputService.close();
    }
  }

  void _onKeepEditorFocusChanged() {
    AppFlowyEditorLog.editor.debug(
      'keyboard service - on keep editor focus changed: ${keepEditorFocusNotifier.value}}',
    );

    if (!keepEditorFocusNotifier.shouldKeepFocus) {
      focusNode.requestFocus();
    }
  }

  // only verify on macOS.
  void _updateCaretPosition(Selection? selection) {
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) {
      return;
    }
    final renderBox = node.renderBox;
    final selectable = node.selectable;
    if (renderBox != null && selectable != null) {
      final size = renderBox.size;
      final transform = renderBox.getTransformTo(null);
      final rect = selectable.getCursorRectInPosition(
        selection.end,
        shiftWithBaseOffset: true,
      );
      if (rect != null) {
        textInputService.updateCaretPosition(size, transform, rect);
      }
    }
  }

  NonDeltaTextInputService buildTextInputService() {
    return NonDeltaTextInputService(
      shouldApplyImeUpdate:
          PlatformExtension.isAndroid ? _shouldApplyAndroidImeUpdate : null,
      onInsert: (insertion) async {
        for (final interceptor in interceptors) {
          final result = await interceptor.interceptInsert(
            insertion,
            editorState,
            widget.characterShortcutEvents,
          );
          if (result) {
            AppFlowyEditorLog.input.info(
              'keyboard service onInsert - intercepted by interceptor: $interceptor',
            );
            return false;
          }
        }

        await onInsert(
          insertion,
          editorState,
          widget.characterShortcutEvents,
        );
        return true;
      },
      onDelete: (deletion) async {
        for (final interceptor in interceptors) {
          final result = await interceptor.interceptDelete(
            deletion,
            editorState,
          );
          if (result) {
            AppFlowyEditorLog.input.info(
              'keyboard service onDelete - intercepted by interceptor: $interceptor',
            );
            return false;
          }
        }

        await onDelete(
          deletion,
          editorState,
        );
        return true;
      },
      onReplace: (replacement) async {
        for (final interceptor in interceptors) {
          final result = await interceptor.interceptReplace(
            replacement,
            editorState,
            widget.characterShortcutEvents,
          );
          if (result) {
            AppFlowyEditorLog.input.info(
              'keyboard service onReplace - intercepted by interceptor: $interceptor',
            );
            return false;
          }
        }

        await onReplace(
          replacement,
          editorState,
          widget.characterShortcutEvents,
        );
        return true;
      },
      onNonTextUpdate: (nonTextUpdate) async {
        for (final interceptor in interceptors) {
          final result = await interceptor.interceptNonTextUpdate(
            nonTextUpdate,
            editorState,
            widget.characterShortcutEvents,
          );
          if (result) {
            AppFlowyEditorLog.input.info(
              'keyboard service onNonTextUpdate - intercepted by interceptor: $interceptor',
            );
            return false;
          }
        }

        await onNonTextUpdate(
          nonTextUpdate,
          editorState,
          widget.characterShortcutEvents,
        );
        return true;
      },
      onPerformAction: (action) async {
        for (final interceptor in interceptors) {
          final result = await interceptor.interceptPerformAction(
            action,
            editorState,
          );
          if (result) {
            AppFlowyEditorLog.input.info(
              'keyboard service onPerformAction - intercepted by interceptor: $interceptor',
            );
            return;
          }
        }

        await onPerformAction(
          action,
          editorState,
        );
      },
      onFloatingCursor: (point) async {
        for (final interceptor in interceptors) {
          final result = await interceptor.interceptFloatingCursor(
            point,
            editorState,
          );
          if (result) {
            AppFlowyEditorLog.input.info(
              'keyboard service onFloatingCursor - intercepted by interceptor: $interceptor',
            );
            return;
          }
        }

        await onFloatingCursorUpdate(
          point,
          editorState,
        );
      },
      contentInsertionConfiguration: widget.contentInsertionConfiguration,
    );
  }
}
