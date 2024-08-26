import 'package:auther/hash.dart';
import 'package:auther/main.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';

class QRCodePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AutherState>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Your code'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: QrImageView(
              data: AutherHash.qrFromHash(appData.userHash),
              version: QrVersions.auto,
              backgroundColor: Colors.white,
              eyeStyle:
                  QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
              dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}
