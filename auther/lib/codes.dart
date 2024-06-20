import 'dart:developer';

import 'package:auther/hash.dart';
import 'package:auther/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class CodeListPage extends StatefulWidget {
  @override
  State<CodeListPage> createState() => _CodeListPageState();
}

class _CodeListPageState extends State<CodeListPage>
    with TickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
        vsync: this,
        duration:
            Duration(milliseconds: AutherHash.refreshIntervalSeconds * 1000));
    _refresh();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    var existingRef = AutherHash.getRef();
    var millisUntilChange = AutherHash.getMillisUntilChange();
    log("Waiting $millisUntilChange ms");
    _progressController.forward(from: AutherHash.getProgressUntilChange());
    await Future.delayed(Duration(milliseconds: millisUntilChange));
    while (AutherHash.getRef() == existingRef) {
      log("Waiting extra 1s");
      await Future.delayed(Duration(milliseconds: 1000));
    }
    if (mounted) {
      setState(() {});
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AutherState>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/codes/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return LinearProgressIndicator(value: _progressController.value);
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: appState.codes.length,
              itemBuilder: (context, index) {
                return CodeCard(codeInfo: appState.codes[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Person {
  Person({
    required this.passphraseHashed,
    this.name = "Default Title",
  });

  final String passphraseHashed;
  final String name;

  String getCode(String myPassphraseHashed) {
    return AutherHash.getOTP(myPassphraseHashed, passphraseHashed);
  }
}

class CodeCard extends StatefulWidget {
  const CodeCard({
    super.key,
    required this.codeInfo,
  });

  final Person codeInfo;

  @override
  State<CodeCard> createState() => _CodeCardState();
}

class _CodeCardState extends State<CodeCard> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AutherState>(context, listen: false);

    return Dismissible(
      key: ObjectKey(widget),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {},
      confirmDismiss: (DismissDirection direction) async {
        setState(() {
          _editing = !_editing;
        });
        return false;
      },
      background: Container(
        color: Theme.of(context).splashColor,
      ),
      child: AnimatedSize(
        duration: Duration(milliseconds: 200),
        curve: standardEasing,
        alignment: Alignment.topCenter,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onLongPress: () => Clipboard.setData(
                  ClipboardData(
                      text:
                          widget.codeInfo.getCode(appState.myPassphraseHashed)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _editing
                      ? _entryField(appState.myPassphraseHashed)
                      : _codeDetails(appState.myPassphraseHashed),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  final _textController = TextEditingController();
  bool _editing = false;

  _codeDetails(String myPassphraseHashed) {
    return CardInfo(
        myPassphraseHashed: myPassphraseHashed, codeInfo: widget.codeInfo);
  }

  _entryField(String myPassphraseHashed) {
    final formKey = GlobalKey<FormState>();

    validate() {
      if (_textController.text.isNotEmpty && formKey.currentState!.validate()) {
        _celebrateValidation();
      }
    }

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Text(
              'Enter ${widget.codeInfo.name}\'s codewords',
            ),
          ),
          TextFormField(
            controller: _textController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.visiblePassword,
            onFieldSubmitted: (value) => validate(),
            validator: (value) {
              if (value == null ||
                  !AutherHash.compareCodewords(
                      AutherHash.getOTP(
                          myPassphraseHashed, widget.codeInfo.passphraseHashed),
                      value)) {
                return 'Invalid code';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                validate();
              },
              child: const Text('Check'),
            ),
          ),
        ],
      ),
    );
  }

  _celebrateValidation() {
    _editing = false;
    setState(() {});
  }
}

class CardInfo extends StatelessWidget {
  const CardInfo({required this.myPassphraseHashed, required this.codeInfo});
  final String myPassphraseHashed;
  final Person codeInfo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          codeInfo.name,
        ),
        const SizedBox(height: 8),
        Text(
          codeInfo.getCode(myPassphraseHashed),
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
