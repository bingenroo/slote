/// Active drawing instrument for new strokes.
enum DrawTool {
  pen,
  eraser,
  highlighter,
  shape,
}

DrawTool parseDrawTool(Object? raw) {
  if (raw is! String) return DrawTool.pen;
  for (final t in DrawTool.values) {
    if (t.name == raw || t.toString() == raw) return t;
  }
  return DrawTool.pen;
}
