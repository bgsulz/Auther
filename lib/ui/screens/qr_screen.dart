import 'package:auther/services/auth_service.dart';

import '../../state/auther_state.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import '../widgets/countdown.dart';
import '../widgets/color_strip.dart';

class QRCodePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AutherState>(context);
    final now = DateTime.now().millisecondsSinceEpoch;
    final slot = AutherAuth.currentSlot(now);
    return Scaffold(
      appBar: AppBar(
        title: Text('Your code'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: QrImageView(
                  data: AutherAuth.qrEncode(appData.userHash, slot),
                  version: QrVersions.auto,
                  backgroundColor: Colors.white,
                  eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                  dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                ),
              ),
              const SizedBox(height: 16),
              const CountdownBar(),
              const SizedBox(height: 8),
              ColorStrip(slot: slot, height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
