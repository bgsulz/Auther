import '../auther_widgets/appbar.dart';
import '../state.dart';

import '../auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class CodeListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AutherState>(context);

    return Scaffold(
      floatingActionButton: _buildFab(context),
      body: _buildBody(context, appState),
    );
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.pushNamed(context, '/codes/scan');
      },
      tooltip: 'Add a new code',
      child: const Icon(Icons.add),
    );
  }

  Widget _buildBody(BuildContext context, AutherState appState) {
    return CustomScrollView(
      slivers: [
        AutherAppBar(context: context, appState: appState),
        _buildList(context, appState),
      ],
    );
  }

  Widget _buildList(BuildContext context, AutherState appState) {
    return SliverReorderableList(
      itemBuilder: (context, index) {
        return Dismissible(
          key: Key("${appState.visibleCodes[index].hashCode}"),
          direction: DismissDirection.horizontal,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16),
            color: Colors.blue,
            child: const Icon(
              Icons.edit,
              color: Colors.white,
            ),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              _showEditDialog(context, appState, index);
              return false;
            } else {
              return await _showConfirmDeletionDialog(context, appState, index);
            }
          },
          onDismissed: (dir) {
            var state = Provider.of<AutherState>(context, listen: false);
            state.removePersonAt(index);
          },
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: Colors.red,
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          child: PersonCard(
            person: appState.visibleCodes[index],
            seed: appState.seed,
            userHash: appState.userHash,
            index: index,
          ),
        );
      },
      itemCount: appState.visibleCodes.length,
      onReorder: (int oldIndex, int newIndex) {
        appState.reorderPerson(oldIndex, newIndex);
      },
    );
  }

  void _showEditDialog(BuildContext context, AutherState appState, int index) {
    final person = appState.codes[index];
    final nameController = TextEditingController(text: person.name);
    final emergencyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Options'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Edit name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emergencyController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter ${person.name}\'s passphrase (emergency)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                appState.editPersonName(person, nameController.text);
                if (emergencyController.text.isNotEmpty) {
                  var isValid =
                      appState.checkEmergency(person, emergencyController.text);
                  if (!isValid) {
                    // TODO: Change to a validated form -- no snackbar.
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid passphrase')));
                  } else {
                    Navigator.of(context).pop();
                  }
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showConfirmDeletionDialog(
      BuildContext context, AutherState appState, int index) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete code'),
          content: Text(
              "Are you sure you want to delete ${appState.codes[index].name}'s codewords?"),
          actions: [
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }
}

class PersonCard extends StatelessWidget {
  const PersonCard({
    super.key,
    required this.person,
    required this.seed,
    required this.userHash,
    required this.index,
  });

  final Person person;
  final int seed;
  final String userHash;
  final int index;

  Widget _buildAuthCode(BuildContext context, Person person, String userHash,
      int seed, bool isSaying) {
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
                ? person.sayAuthCode(userHash, seed).replaceAll(" ", "\n")
                : person.hearAuthCode(userHash, seed).replaceAll(" ", "\n"),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // print("Rebuilding for person ${person.name} at ${DateTime.now()}.");
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onLongPress: () => Clipboard.setData(
              ClipboardData(text: person.sayAuthCode(userHash, seed)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16).copyWith(left: 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 8),
                  if (person._isBroken) ...[
                    SizedBox(
                      height: 140,
                      child: Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Connection broken.",
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Rescan ${person.name}'s QR code.",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ] else ...[
                    Row(
                      children: [
                        _buildAuthCode(context, person, userHash, seed, true),
                        _buildAuthCode(context, person, userHash, seed, false),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            child: ReorderableDragStartListener(
              index: index,
              child: Container(
                width: 64,
                color: Colors.transparent,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Icon(Icons.drag_indicator,
                      color: Theme.of(context).colorScheme.surfaceBright),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Person {
  Person({
    required this.personHash,
    this.name = "Default Title",
  });

  final String personHash;
  String name;
  bool _isBroken = false;
  bool get isBroken => _isBroken;

  String hearAuthCode(String userHash, int seed) {
    return AutherAuth.getOTP(userHash, personHash, seed);
  }

  String sayAuthCode(String userHash, int seed) {
    return AutherAuth.getOTP(personHash, userHash, seed);
  }

  Person.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        personHash = json['personHash'] as String,
        _isBroken = json['isBroken'] as bool;

  Map<String, dynamic> toJson() => {
        'name': name,
        'personHash': personHash,
        'isBroken': isBroken,
      };

  void breakConnection() {
    print("BREAKING CONNECTION FOR $name");
    _isBroken = true;
  }
}
