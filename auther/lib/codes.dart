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
      floatingActionButton: _buildFab(),
      body: _buildBody(appState),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: () {
        print('Hello World');
      },
      tooltip: 'Print Hello World',
      child: const Icon(Icons.add),
    );
  }

  Widget _buildBody(AutherState appState) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        _buildList(appState),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      snap: false,
      floating: false,
      expandedHeight: 200.0,
      flexibleSpace: const FlexibleSpaceBar(
        title: Text('Auther'),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search for a code',
          onPressed: () {
            // TODO: implement search
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () {
            // TODO: implement settings
          },
        ),
        IconButton(
          icon: const Icon(Icons.qr_code),
          tooltip: 'Scan QR code',
          onPressed: () async {},
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
    print("Rebuilding for person ${person.name} at ${DateTime.now()}.");
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

// class CodeListPage extends StatefulWidget {
//   @override
//   State<CodeListPage> createState() => _CodeListPageState();
// }

// class _CodeListPageState extends State<CodeListPage>
//     with TickerProviderStateMixin {
//   late AnimationController _progressController;

//   @override
//   void initState() {
//     super.initState();
//     _progressController = AnimationController(
//         vsync: this,
//         duration:
//             Duration(milliseconds: AutherHash.refreshIntervalSeconds * 1000));
//     _refresh();
//   }

//   @override
//   void dispose() {
//     _progressController.dispose();
//     super.dispose();
//   }

//   Future<void> _refresh() async {
//     var existingRef = AutherHash.getRef();
//     var millisUntilChange = AutherHash.getMillisUntilChange();
//     log("Waiting $millisUntilChange ms");
//     _progressController.forward(from: AutherHash.getProgressUntilChange());
//     await Future.delayed(Duration(milliseconds: millisUntilChange));
//     while (AutherHash.getRef() == existingRef) {
//       log("Waiting extra 1s");
//       await Future.delayed(Duration(milliseconds: 1000));
//     }
//     if (mounted) {
//       setState(() {});
//       _refresh();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final appState = Provider.of<AutherState>(context, listen: false);

//     return Scaffold(
//       appBar: AppBar(
//         leading: BackButton(),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.settings),
//             onPressed: () => Navigator.pushNamed(context, '/codes/settings'),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           AnimatedBuilder(
//             animation: _progressController,
//             builder: (context, child) {
//               return LinearProgressIndicator(value: _progressController.value);
//             },
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: appState.codes.length,
//               itemBuilder: (context, index) {
//                 return CodeCard(codeInfo: appState.codes[index]);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class CodeCard extends StatefulWidget {
//   const CodeCard({
//     super.key,
//     required this.codeInfo,
//   });

//   final Person codeInfo;

//   @override
//   State<CodeCard> createState() => _CodeCardState();
// }

// class _CodeCardState extends State<CodeCard> {
//   @override
//   Widget build(BuildContext context) {
//     final appState = Provider.of<AutherState>(context, listen: false);

//     return Dismissible(
//       key: ObjectKey(widget),
//       direction: DismissDirection.horizontal,
//       onDismissed: (direction) {},
//       confirmDismiss: (DismissDirection direction) async {
//         setState(() {
//           _editing = !_editing;
//         });
//         return false;
//       },
//       background: Container(
//         color: Theme.of(context).splashColor,
//       ),
//       child: AnimatedSize(
//         duration: Duration(milliseconds: 200),
//         curve: standardEasing,
//         alignment: Alignment.topCenter,
//         child: Row(
//           children: [
//             Expanded(
//               child: InkWell(
//                 onLongPress: () => Clipboard.setData(
//                   ClipboardData(
//                       text:
//                           widget.codeInfo.getCode(appState.myPassphraseHashed)),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: _editing
//                       ? _entryField(appState.myPassphraseHashed)
//                       : _codeDetails(appState.myPassphraseHashed),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   final _textController = TextEditingController();
//   bool _editing = false;

//   _codeDetails(String myPassphraseHashed) {
//     return CardInfo(
//         myPassphraseHashed: myPassphraseHashed, codeInfo: widget.codeInfo);
//   }

//   _entryField(String myPassphraseHashed) {
//     final formKey = GlobalKey<FormState>();

//     validate() {
//       if (_textController.text.isNotEmpty && formKey.currentState!.validate()) {
//         _celebrateValidation();
//       }
//     }

//     return Form(
//       key: formKey,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(top: 8, bottom: 16),
//             child: Text(
//               'Enter ${widget.codeInfo.name}\'s codewords',
//             ),
//           ),
//           TextFormField(
//             controller: _textController,
//             decoration: InputDecoration(
//               border: OutlineInputBorder(),
//             ),
//             keyboardType: TextInputType.visiblePassword,
//             onFieldSubmitted: (value) => validate(),
//             validator: (value) {
//               if (value == null ||
//                   !AutherHash.compareCodewords(
//                       AutherHash.getOTP(
//                           myPassphraseHashed, widget.codeInfo.passphraseHashed),
//                       value)) {
//                 return 'Invalid code';
//               }
//               return null;
//             },
//           ),
//           SizedBox(height: 16),
//           Align(
//             alignment: Alignment.centerRight,
//             child: TextButton(
//               onPressed: () {
//                 validate();
//               },
//               child: const Text('Check'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   _celebrateValidation() {
//     _editing = false;
//     setState(() {});
//   }
// }

// class CardInfo extends StatelessWidget {
//   const CardInfo({required this.myPassphraseHashed, required this.codeInfo});
//   final String myPassphraseHashed;
//   final Person codeInfo;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           codeInfo.name,
//         ),
//         const SizedBox(height: 8),
//         Text(
//           codeInfo.getCode(myPassphraseHashed),
//           style: Theme.of(context)
//               .textTheme
//               .headlineMedium
//               ?.copyWith(fontWeight: FontWeight.bold),
//         ),
//       ],
//     );
//   }
// }
