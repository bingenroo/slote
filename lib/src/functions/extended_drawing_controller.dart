import 'package:flutter_drawing_board/flutter_drawing_board.dart';

class ExtendedDrawingController extends DrawingController {
  ExtendedDrawingController({super.config, super.content});

  void removeLastContent() {
    final history = getHistory;
    if (history.isNotEmpty &&
        currentIndex > 0 &&
        currentIndex <= history.length) {
      history.removeAt(currentIndex - 1);
      // Adjust currentIndex if needed
      // If currentIndex > history.length, set it to history.length
      if (currentIndex > history.length) {
        // ignore: invalid_use_of_protected_member
        super.drawConfig.value =
            super.drawConfig.value.copyWith(); // or update as needed
      }
      cachedImage = null;
      notifyListeners();
    }
  }
}
