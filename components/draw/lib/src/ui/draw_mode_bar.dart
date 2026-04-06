import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../draw_controller.dart';
import 'slote_draw_scaffold.dart';

class DrawModeBar extends StatelessWidget {
  const DrawModeBar({
    super.key,
    required this.controller,
    required this.drawerTitle,
    this.drawerMaxHeight = 520,
    this.onDrawerOpenChanged,
  });

  final DrawController controller;
  final String drawerTitle;
  final double drawerMaxHeight;
  final ValueChanged<bool>? onDrawerOpenChanged;

  Future<void> _openDrawer(BuildContext context) async {
    onDrawerOpenChanged?.call(true);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final screenH = MediaQuery.sizeOf(sheetContext).height;
        final safeBottom = MediaQuery.viewPaddingOf(sheetContext).bottom;
        final sheetBodyHeight = math.min(drawerMaxHeight, screenH * 0.7);

        return Padding(
          padding: EdgeInsets.only(bottom: math.max(8.0, safeBottom)),
          child: SizedBox(
            height: sheetBodyHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    drawerTitle,
                    style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    child: SloteDrawAppDrawerContent(controller: controller),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    onDrawerOpenChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: controller.undoRedoListenable,
          builder: (context, _) {
            return SizedBox(
              height: 56,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.undo),
                    onPressed: controller.canUndo ? controller.undo : null,
                    tooltip: 'Undo',
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo),
                    onPressed: controller.canRedo ? controller.redo : null,
                    tooltip: 'Redo',
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () => _openDrawer(context),
                    tooltip: 'More',
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

