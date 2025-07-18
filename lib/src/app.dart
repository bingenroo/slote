import 'package:flutter/material.dart';
import "package:slote/src/res/string.dart";
import 'package:slote/src/views/home.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: Colors.grey.shade700, // Main color
          secondary: Colors.grey, // Accent color
          onPrimary: Colors.white, // Text/icon color on primary
          // You can add more overrides as needed
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.white, // Match onPrimary
          selectionColor: Colors.white24, // Slightly transparent for selection
          selectionHandleColor: Colors.white, // Match onPrimary
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade700, // Set your preferred color
          foregroundColor: Colors.white, // Text/icon color
          elevation: 0,
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return Colors.grey.shade800;
            }
            if (states.contains(WidgetState.dragged)) {
              return Colors.grey.shade900;
            }
            return Colors.grey.shade600;
          }),
          trackColor: WidgetStateProperty.all(Colors.transparent),
          thickness: WidgetStateProperty.all(8.0),
          radius: const Radius.circular(12.0),
          thumbVisibility: WidgetStateProperty.resolveWith((states) {
            // Show when hovered, dragged, or scrolling
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.dragged) ||
                states.contains(WidgetState.scrolledUnder)) {
              return true;
            }
            return false; // Hide by default
          }),
          trackVisibility: WidgetStateProperty.all(false),
          crossAxisMargin: 2.0,
          mainAxisMargin: 8.0,
          interactive: true,
        ),
      ),
      home: const HomeView(),
    );
  }
}
