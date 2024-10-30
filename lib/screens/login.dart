import 'package:auther/customization/style.dart';

import 'settings.dart';
import '../hash.dart';
import '../state.dart';
import '../customization/config.dart';

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
              Style.autherTitle(context),
              SizedBox(height: 16),
              Consumer<AutherState>(
                builder: (context, appState, child) {
                  return appState.userHash.isEmpty ? SignupForm() : LoginForm();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignupForm extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();

  final _controllerFirst = TextEditingController();
  final _controllerSecond = TextEditingController();

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
              SignupTextField(
                _controllerFirst,
                _controllerSecond,
                'Passphrase',
              ),
              SizedBox(height: 16),
              SignupTextField(
                _controllerSecond,
                _controllerFirst,
                'Passphrase (again)',
                validationErrorKey: 'Passphrases do not match',
              ),
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
      var hash = AutherHash.hashPassphrase(_controllerFirst.text);
      appState.userHash = hash;
      Navigator.pushReplacementNamed(context, "/codes");
    }
  }
}

class SignupTextField extends StatelessWidget {
  SignupTextField(
    this.selfController,
    this.compareController,
    this.labelText, {
    this.validationErrorKey,
  });

  final TextEditingController selfController;
  final TextEditingController compareController;
  final String labelText;
  final String? validationErrorKey;

  @override
  Widget build(BuildContext context) {
    FormFieldValidator<String>? validator;

    if (validationErrorKey == null) {
      validator = null;
    } else {
      validator = (value) {
        if (value.toString().isEmpty ||
            compareController.text.isEmpty ||
            value != compareController.text) {
          return validationErrorKey;
        }
        return null;
      };
    }

    return TextFormField(
      controller: selfController,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: labelText,
      ),
      obscureText: true,
      validator: validator,
    );
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
            onFieldSubmitted: (value) => _onFieldSubmitted(context),
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
                onPressed: () => _onFieldSubmitted(context),
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

  void _onFieldSubmitted(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacementNamed(context, "/codes");
    }
  }
}
