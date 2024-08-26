import 'package:auther/hash.dart';
import 'package:auther/main.dart';
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
        _buildAppBar(context),
        SliverToBoxAdapter(
          child: CountdownBar(),
        ),
        _buildList(appState),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      snap: false,
      floating: false,
      expandedHeight: 200.0,
      flexibleSpace: const FlexibleSpaceBar(
        title: Text('Auther'),
      ),
      actions: [
        // IconButton(
        //   icon: const Icon(Icons.search),
        //   tooltip: 'Search for a code',
        //   onPressed: () {
        //     // TODO: implement search
        //   },
        // ),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () {
            Navigator.pushNamed(context, '/codes/settings');
          },
        ),
        IconButton(
          icon: const Icon(Icons.qr_code),
          tooltip: 'Show QR code',
          onPressed: () {
            Navigator.pushNamed(context, '/codes/qr');
          },
        ),
      ],
    );
  }

  Widget _buildList(AutherState appState) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return PersonCard(
            person: appState.codes[index],
            seed: appState.getSeed(),
            userHash: appState.userHash,
          );
        },
        childCount: appState.codes.length,
      ),
    );
  }
}

class CountdownBar extends StatefulWidget {
  const CountdownBar({
    super.key,
  });

  @override
  CountdownBarState createState() => CountdownBarState();
}

class CountdownBarState extends State<CountdownBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  late AutherState appState;

  @override
  void initState() {
    super.initState();
    appState = Provider.of<AutherState>(context, listen: false);
    _animationController = AnimationController(
        vsync: this,
        duration: Duration(seconds: AutherState.refreshIntervalSeconds),
        upperBound: 1,
        lowerBound: 0,
        reverseDuration:
            Duration(milliseconds: AutherState.refreshIntervalSeconds * 1000),
        value: appState.getProgress());
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        if (_animationController.value <= 0) {
          _animationController.value = appState.getProgress();
          _animationController.reverse();
        }
        return LinearProgressIndicator(
          value: _animationController.value,
        );
      },
    );
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
              Row(
                children: [
                  _buildAuthCode(context, person, userHash, seed, true),
                  _buildAuthCode(context, person, userHash, seed, false),
                ],
              ),
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

  String hearAuthCode(String userHash, int seed) {
    return AutherHash.getOTP(userHash, personHash, seed);
  }

  String sayAuthCode(String userHash, int seed) {
    return AutherHash.getOTP(personHash, userHash, seed);
  }
}
