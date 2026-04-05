/// How the eraser mutates ink when it intersects a pen/highlighter stroke.
enum EraserMode {
  /// Wave D1: remove the entire stroke if the eraser footprint hits it.
  stroke,

  /// Wave D2: split the centerline, keeping only segments outside the footprint.
  pixel,
}
