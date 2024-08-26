import 'package:auther/main.dart';
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
              _showClearPassphraseDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showClearPassphraseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text(
              'This will delete your saved passphrase and clear your list!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _clearPassphrase(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _clearPassphrase(BuildContext context) {
    final appState = Provider.of<AutherState>(context, listen: false);
    appState.userHash = '';
  }
}
