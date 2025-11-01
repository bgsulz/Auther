import 'package:auther/models/person.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auther_state.dart';

class EditPersonScreen extends StatefulWidget {
  const EditPersonScreen({super.key});

  @override
  State<EditPersonScreen> createState() => _EditPersonScreenState();
}

class _EditPersonScreenState extends State<EditPersonScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emergencyController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emergencyController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final personArg = ModalRoute.of(context)!.settings.arguments as Person?;
    if (personArg == null) {
      // If navigated without a person, just go back.
      Future.microtask(() => Navigator.of(context).pop());
      return const SizedBox.shrink();
    }

    // Initialize text on first build after we have the argument
    if (_nameController.text.isEmpty) {
      _nameController.text = personArg.name;
    }

    final appState = Provider.of<AutherState>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: () async {
              final confirm = await _confirmDelete(context, personArg);
              if (confirm) {
                appState.removePerson(personArg);
                if (mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Edit name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emergencyController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: "Enter ${personArg.name}'s passphrase (emergency)",
              ),
              obscureText: true,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _onSave(context, appState, personArg);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSave(BuildContext context, AutherState appState, Person person) async {
    final newName = _nameController.text;
    final pass = _emergencyController.text;

    appState.editPersonName(person, newName);

    if (pass.isNotEmpty) {
      final isValid = appState.checkEmergency(person, pass);
      if (!isValid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid passphrase')),
        );
        return; // stay on screen
      }
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<bool> _confirmDelete(BuildContext context, Person person) async {
    return (await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete code'),
            content: Text("Are you sure you want to delete ${person.name}'s codewords?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }
}
