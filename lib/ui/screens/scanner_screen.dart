import 'package:auther/models/person.dart';

import '../../services/auth_service.dart';
import '../../state/auther_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../widgets/color_strip.dart';

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
    final parsed = AutherAuth.parseQr(qr);
    if (parsed == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!AutherAuth.isSlotAcceptable(parsed['slot'] as int, now)) return;
    final hash = parsed['userHash'] as String;
    final slot = parsed['slot'] as int;

    HapticFeedback.vibrate();

    setState(() {
      _didScan = true;
    });

    showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        final nameController = TextEditingController();
        bool confirmed = false;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      confirmed ? 'Verified now' : 'Do the colors match on both phones?',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    ColorStrip(slot: slot, height: 16),
                    const SizedBox(height: 12),
                    if (!confirmed) ...[
                      Text(
                        'Ask the other person: do you see these 4 colors in this order?\n(Colors change every ~30 seconds.)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('No, try again'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setModalState(() {
                                  confirmed = true;
                                });
                              },
                              child: const Text('Yes, they match'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        'Enter a name for this person.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Enter name',
                        ),
                        controller: nameController,
                        onFieldSubmitted: (value) {
                          if (nameController.text.isNotEmpty) {
                            _savePerson(hash, nameController.text);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (nameController.text.isNotEmpty) {
                              _savePerson(hash, nameController.text);
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
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
