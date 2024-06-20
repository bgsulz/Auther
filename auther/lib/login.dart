import 'package:auther/hash.dart';
import 'package:auther/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Auther',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge!
                      .copyWith(fontWeight: FontWeight.w300, fontSize: 64)),
              SizedBox(height: 16),
              PassphraseForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class PassphraseForm extends StatefulWidget {
  const PassphraseForm({
    super.key,
  });

  @override
  State<PassphraseForm> createState() => _PassphraseFormState();
}

class _PassphraseFormState extends State<PassphraseForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Passphrase',
              helperText: 'Enter your passphrase here',
            ),
            obscureText: true,
            validator: (value) {
              final appState = Provider.of<AutherState>(context, listen: false);
              if (value!.isNotEmpty && appState.myPassphraseHashed.isEmpty) {
                appState.myPassphraseHashed = AutherHash.hashPassphrase(value);
                return null;
              } else if (AutherHash.hashPassphrase(value) !=
                  appState.myPassphraseHashed) {
                return 'Invalid passphrase';
              } else {
                return null;
              }
            },
            onFieldSubmitted: (value) {
              if (_formKey.currentState!.validate()) {
                Navigator.pushNamed(context, "/codes");
              }
            },
          ),
        ],
      ),
    );
  }
}
