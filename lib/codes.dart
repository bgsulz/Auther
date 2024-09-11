import 'package:auther/auther_widgets/appbar.dart';

import 'hash.dart';
import 'main.dart';
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
        _buildList(appState),
      ],
    );
  }

  Widget _buildList(AutherState appState) {
    var indices = <int>[];

    var query = appState.searchController.text;
    if (query.isEmpty) {
      indices = List.generate(appState.codes.length, (index) => index);
    } else {
      indices = appState.codes
          .asMap()
          .entries
          .where((element) => element.value.name
              .toLowerCase()
              .contains(query.toLowerCase().trim()))
          .map((e) => e.key)
          .toList();
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Dismissible(
            key: Key(appState.codes[indices[index]].name),
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
                return await _showConfirmDeletionDialog(
                    context, appState, index);
              }
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
              person: appState.codes[indices[index]],
              seed: appState.getSeed(),
              userHash: appState.userHash,
            ),
          );
        },
        childCount: indices.length,
      ),
    );
  }

  void _showEditDialog(BuildContext context, AutherState appState, int index) {
    final appState = Provider.of<AutherState>(context, listen: false);
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
                    labelText: 'Enter person\'s passphrase (emergency)',
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
  });

  final Person person;
  final int seed;
  final String userHash;

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
      child: InkWell(
        onLongPress: () => Clipboard.setData(
          ClipboardData(text: person.sayAuthCode(userHash, seed)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
    );
  }
}

class Person {
  Person({
    required this.personHash,
    this.name = "Default Title",
  });

  final String personHash;
  final String name;
  bool _isBroken = false;
  bool get isBroken => _isBroken;

  String hearAuthCode(String userHash, int seed) {
    return AutherHash.getOTP(userHash, personHash, seed);
  }

  String sayAuthCode(String userHash, int seed) {
    return AutherHash.getOTP(personHash, userHash, seed);
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
