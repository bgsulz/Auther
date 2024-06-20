import 'package:flutter/material.dart';

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
            title: const Text('Theme'),
            subtitle: const Text('Change the color theme'),
            trailing: Icon(Icons.color_lens),
          ),
          ListTile(
            title: const Text('Autofill'),
            subtitle: const Text('Automatically fill in login details'),
            trailing: const Switch(
              value: false,
              onChanged: null,
            ),
          ),
          ListTile(
            title: const Text('Password management'),
            subtitle: const Text('Manage saved passwords'),
            trailing: Icon(Icons.vpn_key),
          ),
          ListTile(
            title: const Text('Account management'),
            subtitle: const Text('Manage your accounts'),
            trailing: Icon(Icons.account_circle),
          ),
        ],
      ),
    );
  }
}
