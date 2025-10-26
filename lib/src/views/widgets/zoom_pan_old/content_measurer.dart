import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ContentMeasurer extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onSizeChanged;

  const ContentMeasurer({
    super.key,
    required this.child,
    required this.onSizeChanged,
  });

  @override
  State<ContentMeasurer> createState() => _ContentMeasurerState();
}

class _ContentMeasurerState extends State<ContentMeasurer> {
  @override
  Widget build(BuildContext context) {
    return MeasureSize(onChange: widget.onSizeChanged, child: widget.child);
  }
}

class MeasureSize extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onChange;

  const MeasureSize({super.key, required this.onChange, required Widget child})
    : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChange);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _MeasureSizeRenderObject renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  ValueChanged<Size> onChange;
  Size? _oldSize;

  _MeasureSizeRenderObject(this.onChange);

  @override
  void performLayout() {
    super.performLayout();
    Size newSize = child!.size;
    if (_oldSize != newSize) {
      _oldSize = newSize;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChange(newSize);
      });
    }
  }
}
