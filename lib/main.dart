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
import 'repositories/file_auther_repository.dart';
import 'repositories/secure_storage_repository.dart';
import 'repositories/auth_ticker_service.dart';

void main() {
  runApp(AutherApp());
}

class AutherApp extends StatelessWidget {
  const AutherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AutherState(
        repository: FileAutherRepository(),
        secureStorage: storage,
        ticker: AuthTicker(),
      ),
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
