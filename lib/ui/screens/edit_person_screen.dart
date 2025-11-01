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

    final appState = Provider.of<AutherState>(context);
    // Resolve the latest person state by hash so we reflect updates (e.g., isBroken)
    final person = appState.codes.firstWhere(
      (p) => p.personHash == personArg.personHash,
      orElse: () => personArg,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit code'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Codes section
            _buildCodes(context, person, appState.userHash, appState.seed),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Edit name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Edit name',
              ),
            ),

            const SizedBox(height: 16),

            if (!person.isBroken) ...[
              // Emergency description
              Text(
                'Emergency option: If one person cannot access their phone, they can provide their passphrase to break the connection. This lets you complete 2FA in a pinch, but it compromises their passcode and permanently breaks the secure link until you rescan their QR code.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 12),

              // Emergency option input
              TextField(
                controller: _emergencyController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: "Enter ${person.name}'s passphrase (emergency)",
                ),
                obscureText: true,
              ),

              const SizedBox(height: 12),
            ],

            // Full-width delete
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () async {
                final confirm = await _confirmDelete(context, personArg);
                if (confirm) {
                  appState.removePerson(personArg);
                  if (mounted) Navigator.of(context).pop();
                }
              },
              child: const Text('Delete this person\'s code'),
            ),

            const Spacer(),

            // Save / Cancel row
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
                      _onSave(context, appState, person);
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

  Widget _buildCodes(
      BuildContext context, Person person, String userHash, int seed) {
    if (person.isBroken) {
      return SizedBox(
        height: 140,
        child: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connection broken.',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  "Rescan ${person.name}'s QR code.",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget buildAuth(bool isSaying) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSaying ? 'Say: ' : 'Hear: ',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              isSaying
                  ? person.sayAuthCode(userHash, seed).replaceAll(' ', '\n')
                  : person.hearAuthCode(userHash, seed).replaceAll(' ', '\n'),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        buildAuth(true),
        buildAuth(false),
      ],
    );
  }

  Future<void> _onSave(
      BuildContext context, AutherState appState, Person person) async {
    final newName = _nameController.text;
    final pass = _emergencyController.text;

    appState.editPersonName(person, newName);

    if (!person.isBroken && pass.isNotEmpty) {
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
            content: Text(
                "Are you sure you want to delete ${person.name}'s codewords?"),
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
