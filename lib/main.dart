import '../state/auther_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'customization/style.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/widgets/codes.dart';
import 'ui/screens/qr_screen.dart';
import 'ui/screens/scanner_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/edit_person_screen.dart';
import 'repositories/file_auther_repository.dart';
import 'repositories/secure_storage_repository.dart';
import 'repositories/auth_ticker_service.dart';

void main() {
  runApp(AutherApp());
}

class AutherApp extends StatefulWidget {
  const AutherApp({super.key});

  @override
  State<AutherApp> createState() => _AutherAppState();
}

class _AutherAppState extends State<AutherApp> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AutherState(
        repository: FileAutherRepository(),
        secureStorage: storage,
        ticker: AuthTicker(),
      ),
      child: Consumer<AutherState>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'Auther',
            theme: ThemeData(
              brightness: Brightness.light,
              textTheme: Style.textTheme,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              textTheme: Style.textTheme,
            ),
            themeMode: appState.themeMode,
            routes: routes,
          );
        },
      ),
    );
  }

  Map<String, WidgetBuilder> get routes {
    return {
      '/': (context) => SplashScreen(),
      '/intro': (context) => IntroPage(),
      '/login': (context) => LoginPage(),
      '/codes': (context) => CodeListPage(),
      '/codes/edit': (context) => EditPersonScreen(),
      '/codes/scan': (context) => CodeScanPage(),
      '/codes/qr': (context) => QRCodePage(),
      '/codes/settings': (context) => SettingsPage(),
    };
  }
}
