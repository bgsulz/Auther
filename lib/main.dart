import 'package:auther/secure.dart';
import 'package:auther/state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'customization/style.dart';
import 'screens/splash.dart';
import 'screens/login.dart';
import 'auther_widgets/codes.dart';
import 'screens/qr.dart';
import 'screens/scanner.dart';
import 'screens/settings.dart';

final storage = SecureStorageService();

void main() {
  runApp(AutherApp());
}

class AutherApp extends StatelessWidget {
  const AutherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AutherState(),
      child: MaterialApp(
        title: 'Auther',
        theme: ThemeData(
          brightness: Brightness.dark,
          textTheme: TextTheme(
            displayLarge: Style.serif(),
            displayMedium: Style.serif(),
            displaySmall: Style.serif(),
            headlineLarge: Style.serif(),
            headlineMedium: Style.serif(),
            headlineSmall: Style.serif(),
            titleLarge: Style.serif(),
            titleMedium: Style.serif(),
            titleSmall: Style.serif(),
          ),
        ),
        routes: {
          '/': (context) => SplashScreen(),
          '/intro': (context) => IntroPage(),
          '/login': (context) => LoginPage(),
          '/codes': (context) => CodeListPage(),
          '/codes/scan': (context) => CodeScanPage(),
          '/codes/qr': (context) => QRCodePage(),
          '/codes/settings': (context) => SettingsPage(),
        },
      ),
    );
  }
}
