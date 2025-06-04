import 'package:flutter/material.dart';
import "package:slote/src/res/string.dart";
import 'package:slote/src/views/home.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: ThemeData(useMaterial3: true),
      home: const HomeView(),
    );
  }
}
