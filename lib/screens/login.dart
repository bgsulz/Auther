import 'package:auther/hash.dart';
import 'package:auther/state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../customization/config.dart';
import 'settings.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AutherState>(context, listen: false);

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
                      .copyWith(fontSize: 64)),
              SizedBox(height: 16),
              appState.userHash.isEmpty ? SignupForm() : LoginForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class SignupForm extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();

  final _passphrase1Controller = TextEditingController();
  final _passphrase2Controller = TextEditingController();

  TextFormField _buildTextFormField(TextEditingController controller,
      TextEditingController other, String labelText,
      {String? validationErrorKey}) {
    String? Function(dynamic value)? validator;
    if (validationErrorKey == null) {
      validator = null;
    } else {
      validator = (value) {
        if (value.toString().isEmpty ||
            other.text.isEmpty ||
            value != other.text) {
          return validationErrorKey;
        }
        return null;
      };
    }

    return TextFormField(
        controller: controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: labelText,
        ),
        obscureText: true,
        validator: validator);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Config.passphraseEnter,
            style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 8),
        const Text(Config.passphraseGuidelines),
        SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextFormField(
                  _passphrase1Controller, _passphrase2Controller, 'Passphrase'),
              SizedBox(height: 16),
              _buildTextFormField(_passphrase2Controller,
                  _passphrase1Controller, 'Passphrase (again)',
                  validationErrorKey: 'Passphrases do not match'),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _onSubmit(context),
                  child: const Text('Set Passphrase'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onSubmit(BuildContext context) {
    final appState = Provider.of<AutherState>(context, listen: false);

    if (_formKey.currentState!.validate()) {
      var hash = AutherHash.hashPassphrase(_passphrase1Controller.text);
      appState.setUserHash(hash);
      Navigator.pushReplacementNamed(context, "/codes");
    }
  }
}

class LoginForm extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AutherState>(context, listen: false);
    final formController = TextEditingController();

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
            controller: formController,
            obscureText: true,
            validator: (value) => _validatePassphrase(appState, value),
            onFieldSubmitted: (value) => _onFieldSubmitted(context, value),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Settings.showResetModal(context),
                child: Text('Forgot password?'),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _onFieldSubmitted(context, formController.text);
                  }
                },
                child: Text('Enter'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _validatePassphrase(AutherState appState, String? value) {
    if (value == null ||
        value.isEmpty ||
        AutherHash.hashPassphrase(value) != appState.userHash) {
      return 'Invalid passphrase';
    } else {
      return null;
    }
  }

  void _onFieldSubmitted(BuildContext context, String value) {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacementNamed(context, "/codes");
    }
  }
}
