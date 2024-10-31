import '../state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'customization/style.dart';
import 'screens/splash.dart';
import 'screens/login.dart';
import 'auther_widgets/codes.dart';
import 'screens/qr.dart';
import 'screens/scanner.dart';
import 'screens/settings.dart';

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
          textTheme: Style.textTheme,
        ),
        routes: routes,
      ),
    );
  }

  Map<String, WidgetBuilder> get routes {
    return {
      '/': (context) => SplashScreen(),
      '/intro': (context) => IntroPage(),
      '/login': (context) => LoginPage(),
      '/codes': (context) => CodeListPage(),
      '/codes/scan': (context) => CodeScanPage(),
      '/codes/qr': (context) => QRCodePage(),
      '/codes/settings': (context) => SettingsPage(),
    };
  }
}
