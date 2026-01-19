import 'package:auther/customization/style.dart';

import 'settings_screen.dart';
import '../../state/auther_state.dart';
import '../../customization/config.dart';

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

class SignupForm extends StatefulWidget {
  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controllerFirst;
  late final TextEditingController _controllerSecond;

  @override
  void initState() {
    super.initState();
    _controllerFirst = TextEditingController();
    _controllerSecond = TextEditingController();
  }

  @override
  void dispose() {
    _controllerFirst.dispose();
    _controllerSecond.dispose();
    super.dispose();
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
      () async {
        await appState.setPassphrase(_controllerFirst.text);
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, "/codes");
        }
      }();
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

class LoginForm extends StatefulWidget {
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _formController;
  bool _biometricAttempted = false;
  bool _showPassphraseForm = false;

  @override
  void initState() {
    super.initState();
    _formController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptBiometricLogin();
    });
  }

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  Future<void> _attemptBiometricLogin() async {
    if (_biometricAttempted) return;
    _biometricAttempted = true;

    final appState = Provider.of<AutherState>(context, listen: false);
    if (!appState.biometricValid) {
      setState(() => _showPassphraseForm = true);
      return;
    }

    final success = await appState.attemptBiometricLogin();
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, "/codes");
    } else if (mounted) {
      setState(() => _showPassphraseForm = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AutherState>(context, listen: false);

    if (!_showPassphraseForm) {
      return const Center(child: CircularProgressIndicator());
    }

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
            controller: _formController,
            obscureText: true,
            validator: (value) => (value == null || value.isEmpty) ? 'Passphrase must not be empty' : null,
            onFieldSubmitted: (value) => _onFieldSubmitted(context, appState, _formController.text),
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
                onPressed: () => _onFieldSubmitted(context, appState, _formController.text),
                child: Text('Enter'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onFieldSubmitted(BuildContext context, AutherState appState, String value) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await appState.validatePassphrase(value);
    if (ok) {
      // Reset biometric timer if biometric was previously enabled
      if (appState.biometricEnabled) {
        await appState.recordBiometricAuth();
      }
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, "/codes");
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid passphrase')),
        );
      }
    }
  }
}
