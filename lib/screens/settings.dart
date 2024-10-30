import 'package:auther/state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: BackButton(),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Clear passphrase'),
            subtitle: const Text("This will clear your entire list!"),
            trailing: Icon(Icons.clear),
            onTap: () {
              Settings.showResetModal(context);
            },
          ),
        ],
      ),
    );
  }
}

class Settings {
  static void showResetModal(BuildContext context) {
    final navigator = Navigator.of(context);
    final appState = Provider.of<AutherState>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Forgot password'),
          content: Text(
              "Resetting your password will delete all of your codewords. Are you sure you want to do this?"),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                appState.reset();
                navigator.pushReplacementNamed("/login");
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}
