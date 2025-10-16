import '../../customization/config.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadAndRedirect(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return SizedBox.shrink(); // Placeholder, as navigation will occur
        } else {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  Future<void> _loadAndRedirect(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey("has_visited") ||
        prefs.getBool("has_visited") == false) {
      prefs.setBool("has_visited", true);
      if (context.mounted) Navigator.pushReplacementNamed(context, "/intro");
    } else {
      if (context.mounted) Navigator.pushReplacementNamed(context, "/login");
    }
  }
}

class IntroPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(Config.autherSubtitle,
                  style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 16),
              const Text(Config.autherDescription),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "/login");
                  },
                  child: Text("Next"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
