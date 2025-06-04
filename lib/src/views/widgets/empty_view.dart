import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:slote/src/res/assets.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Lottie.asset(AnimationAssets.empty),
        Text(
          "Such emptiness... Tap + to slote!",
          style: GoogleFonts.poppins(fontSize: 16),
        ),
      ],
    );
  }
}
