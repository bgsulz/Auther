import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'codes.dart';
import 'login.dart';
import 'settings.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AutherState(),
      child: MaterialApp(
        title: 'Namer App',
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData.dark(),
        routes: {
          '/': (context) => LoginPage(),
          '/codes': (context) => CodeListPage(),
          '/codes/settings': (context) => SettingsPage(),
        },
      ),
    );
  }
}

class AutherState extends ChangeNotifier {
  List<Person> codes = [Person(passphraseHashed: "aaa"), Person(passphraseHashed: "bbb")];
  String myPassphraseHashed = "";
}