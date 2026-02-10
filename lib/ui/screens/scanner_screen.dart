import 'package:auther/models/person.dart';

import '../../services/auth_service.dart';
import '../../state/auther_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../widgets/color_strip.dart';
import '../widgets/error_snackbar.dart';

class CodeScanPage extends StatefulWidget {
  const CodeScanPage({super.key});

  @override
  State<CodeScanPage> createState() => _CodeScanPageState();
}

class _CodeScanPageState extends State<CodeScanPage> {
  bool _didScan = false;
  bool _isSimulation = false;
  DateTime _lastErrorTime = DateTime(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['simulate'] == true && !_didScan) {
      _isSimulation = true;
      final now = DateTime.now().millisecondsSinceEpoch;
      final int slot = (args['slot'] as int?) ?? AutherAuth.currentSlot(now);
      final String hash = (args['hash'] as String?) ??
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _didScan = true;
        });
        _showConfirmSheet(context, hash, slot);
      });
    }
  }

  void _showConfirmSheet(BuildContext context, String hash, int slot) {
    showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return _ConfirmSheetContent(
          hash: hash,
          slot: slot,
          onSave: _savePerson,
        );
      },
    ).then((_) {
      if (!mounted) return;

      if (_isSimulation) {
        // For simulations, dismissing the sheet should exit the scanner
        if (context.mounted) Navigator.of(context).pop();
      } else {
        // For real scans, allow scanning again
        setState(() {
          _didScan = false;
        });
      }
    });
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (!mounted) return;
    if (_didScan) return;

    var found = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    if (found == null) return;

    var qr = found.displayValue;
    if (qr == null) return;
    final parsed = AutherAuth.parseQr(qr);
    if (parsed == null) {
      _showScanError('Not a valid Auther QR code');
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!AutherAuth.isSlotAcceptable(parsed['slot'] as int, now)) {
      _showScanError('QR code has expired — ask them to refresh');
      return;
    }
    final hash = parsed['userHash'] as String;
    final slot = parsed['slot'] as int;

    // Set flag before setState to prevent race condition with rapid scans
    _didScan = true;

    HapticFeedback.vibrate();

    setState(() {});

    _showConfirmSheet(context, hash, slot);
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

  void _showScanError(String message) {
    final now = DateTime.now();
    if (now.difference(_lastErrorTime).inSeconds < 2) return;
    _lastErrorTime = now;
    ErrorSnackbar.showError(context, message);
  }

  void _savePerson(String hash, String name) {
    final appState = Provider.of<AutherState>(context, listen: false);
    appState.addPerson(Person(name: name, personHash: hash));
    Navigator.pop(context); // Close bottom sheet
    Navigator.pop(context); // Go back to codes
  }
}

/// Separate StatefulWidget for the confirmation sheet content.
/// This ensures state (confirmed, nameController) survives keyboard rebuilds.
class _ConfirmSheetContent extends StatefulWidget {
  final String hash;
  final int slot;
  final void Function(String hash, String name) onSave;

  const _ConfirmSheetContent({
    required this.hash,
    required this.slot,
    required this.onSave,
  });

  @override
  State<_ConfirmSheetContent> createState() => _ConfirmSheetContentState();
}

class _ConfirmSheetContentState extends State<_ConfirmSheetContent> {
  final TextEditingController _nameController = TextEditingController();
  bool _confirmed = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _confirmed ? 'Verified now' : 'Do the colors match on both phones?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            ColorStrip(slot: widget.slot, height: 16),
            const SizedBox(height: 12),
            if (!_confirmed) ...[
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
                        setState(() {
                          _confirmed = true;
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
                controller: _nameController,
                autofocus: true,
                onFieldSubmitted: (value) {
                  if (_nameController.text.isNotEmpty) {
                    widget.onSave(widget.hash, _nameController.text);
                  }
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_nameController.text.isNotEmpty) {
                      widget.onSave(widget.hash, _nameController.text);
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
