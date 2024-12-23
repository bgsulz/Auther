import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

import '../auther_widgets/codes.dart';
import '../auth.dart';
import '../state.dart';

import 'package:flutter/foundation.dart';
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
          _buildResetListTile(context),
          _buildExportTile(context),
          _buildImportTile(context),
          if (kDebugMode) _buildSamplePeopleListTile(context),
        ],
      ),
    );
  }

  ListTile _buildSamplePeopleListTile(BuildContext context) {
    return ListTile(
      title: const Text('Add sample persons'),
      leading: Icon(Icons.person_add),
      onTap: () {
        Settings.addSamplePersons(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sample people added'),
          ),
        );
      },
    );
  }

  ListTile _buildResetListTile(BuildContext context) {
    return ListTile(
      title: const Text('Clear passphrase'),
      subtitle: const Text("This will clear your entire list!"),
      leading: Icon(Icons.delete_forever),
      onTap: () {
        Settings.showResetModal(context);
      },
    );
  }

  ListTile _buildExportTile(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.upload),
      title: const Text('Export registered persons'),
      onTap: () {
        Settings.export(context);
      },
    );
  }

  ListTile _buildImportTile(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.download),
      title: const Text('Import registered persons'),
      onTap: () {
        Settings.import(context);
      },
    );
  }
}

class Settings {
  static void showResetModal(BuildContext context) {
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
              onPressed: () => Navigator.of(context).pop(),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                appState.resetAll();
                Navigator.of(context).pushReplacementNamed("/login");
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  static void addSamplePersons(BuildContext context) {
    final appState = Provider.of<AutherState>(context, listen: false);

    var codes = [
      Person(name: "Zachary", personHash: AutherAuth.hashPassphrase("1234")),
      Person(name: "Samantha", personHash: AutherAuth.hashPassphrase("5678")),
      Person(name: "Elijah", personHash: AutherAuth.hashPassphrase("9012")),
      Person(name: "Lillian", personHash: AutherAuth.hashPassphrase("3456")),
      Person(name: "Logan", personHash: AutherAuth.hashPassphrase("7890")),
      Person(name: "Ava", personHash: AutherAuth.hashPassphrase("2468")),
      Person(name: "William", personHash: AutherAuth.hashPassphrase("1357")),
      Person(name: "Sophia", personHash: AutherAuth.hashPassphrase("4680")),
      Person(name: "Oliver", personHash: AutherAuth.hashPassphrase("7531")),
      Person(name: "Mia", personHash: AutherAuth.hashPassphrase("8629")),
    ];

    while (appState.codes.isNotEmpty) {
      appState.removePersonAt(0);
    }

    for (var code in codes) {
      appState.addPerson(code);
    }
  }

  static String _generateTimecode() {
    var now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }

  static Future<void> export(BuildContext context) async {
    final appState = Provider.of<AutherState>(context, listen: false);

    var filename = 'auther_data_${_generateTimecode()}.json';
    var file = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Auther data',
        fileName: filename,
        bytes: utf8.encode(appState.dataJson));

    if (context.mounted) {
      if (file == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auther export canceled')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auther data exported successfully!')),
        );
      }
    }
  }

  static Future<void> import(BuildContext context) async {
    final appState = Provider.of<AutherState>(context, listen: false);
    final result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      await appState.loadFromFile(file);
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/codes');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auther data successfully imported!')),
        );
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auther data import canceled')),
      );
    }
  }
}
