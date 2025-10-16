import 'package:auther/models/person.dart';

import '../../services/auth_service.dart';
import '../../state/auther_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

class CodeScanPage extends StatefulWidget {
  const CodeScanPage({super.key});

  @override
  State<CodeScanPage> createState() => _CodeScanPageState();
}

class _CodeScanPageState extends State<CodeScanPage> {
  bool _didScan = false;

  void _handleBarcode(BarcodeCapture capture) {
    if (!mounted) return;
    if (_didScan) return;

    var found = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    if (found == null) return;

    var qr = found.displayValue;
    if (qr == null) return;
    if (!AutherAuth.isPlausibleQr(qr)) return;

    var hash = AutherAuth.hashFromQr(qr);

    HapticFeedback.vibrate();

    setState(() {
      _didScan = true;
    });

    showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        final nameController = TextEditingController();

        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Successfully scanned!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Enter name',
                    ),
                    controller: nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Name must not be empty';
                      } else {
                        return null;
                      }
                    },
                    onFieldSubmitted: (value) {
                      if (nameController.text.isNotEmpty) {
                        _savePerson(hash, nameController.text);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((enteredName) {
      if (mounted) {
        setState(() {
          print("CLOSING BOTTOM SHEET");
          _didScan = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR code')),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleBarcode,
          ),
        ],
      ),
    );
  }

  void _savePerson(String hash, String name) {
    final appState = Provider.of<AutherState>(context, listen: false);
    appState.addPerson(Person(name: name, personHash: hash));
    Navigator.pop(context); // Close bottom sheet
    Navigator.pop(context); // Go back to codes
  }
}
