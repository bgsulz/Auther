import 'package:auther/models/person.dart';
import 'package:auther/services/auth_service.dart';

import 'appbar.dart';
import '../../state/auther_state.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class CodeListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AutherState>(context);
    final userHash = appState.userHash;
    if (userHash.isEmpty || !AutherAuth.isPlausibleHash(userHash)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
        final person = appState.visibleCodes[index];
        return Dismissible(
          key: ValueKey(person.personHash),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await _showConfirmDeletionDialog(context, appState, person);
          },
          onDismissed: (dir) {
            var state = Provider.of<AutherState>(context, listen: false);
            state.removePerson(person);
          },
          background: const SizedBox.shrink(),
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
            person: person,
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

  Future<bool> _showConfirmDeletionDialog(
      BuildContext context, AutherState appState, Person person) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete code'),
          content: Text(
              "Are you sure you want to delete ${person.name}'s codewords?"),
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
    final code = isSaying
        ? AutherAuth.getSayCode(userHash, person.personHash, seed)
        : AutherAuth.getHearCode(userHash, person.personHash, seed);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSaying ? 'Say: ' : 'Hear: ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            code.replaceAll(" ", "\n"),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              '/codes/edit',
              arguments: person,
            ),
            onLongPress: () {
              final code = AutherAuth.getSayCode(userHash, person.personHash, seed);
              Clipboard.setData(ClipboardData(text: code));
              // Auto-clear clipboard after 60 seconds for security
              Future.delayed(const Duration(seconds: 60), () {
                Clipboard.setData(const ClipboardData(text: ''));
              });
            },
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
                  if (person.isBroken) ...[
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
