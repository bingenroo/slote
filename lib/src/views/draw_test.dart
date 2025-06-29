//simple example

import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter/material.dart';

class DrawTest extends StatelessWidget {
  const DrawTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DrawingBoard(
            background: Container(width: 400, height: 400, color: Colors.white),

            /// Enable default action options
            showDefaultActions: true,

            /// Enable default toolbar
            showDefaultTools: true,
          ),
        ],
      ),
    );
  }
}
