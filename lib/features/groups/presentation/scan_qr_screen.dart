import 'package:flutter/material.dart';
import 'package:hulaki/l10n/app_localizations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Points the camera at an invite QR and returns the decoded text. The caller
/// validates it and joins.
class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled || capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupScanInviteQrTitle)),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
