import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slote/src/providers/theme_provider.dart';
import 'package:slote/src/res/theme_config.dart';
import 'package:slote/src/res/string.dart';
import 'package:slote/src/views/home.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: AppStrings.appName,
            theme: AppThemeConfig.lightTheme,
            darkTheme: AppThemeConfig.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const HomeView(),
          );
        },
      ),
    );
  }
}
