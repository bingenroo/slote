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
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade700, // Set your preferred color
          foregroundColor: Colors.white, // Text/icon color
          elevation: 0,
        ),
      ),
      home: const HomeView(),
    );
  }
}
