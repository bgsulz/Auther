import 'package:auther/config.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SharedPreferences.getInstance().then((prefs) {
      if (!prefs.containsKey("has_visited") ||
          prefs.getBool("has_visited") == false) {
        prefs.setBool("has_visited", true);
        if (context.mounted) Navigator.pushNamed(context, "/intro");
      } else {
        if (context.mounted) Navigator.pushNamed(context, "/login");
      }
    });

    return Scaffold(
      body: Center(
        child: Text(
          "Auther",
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

class IntroPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
