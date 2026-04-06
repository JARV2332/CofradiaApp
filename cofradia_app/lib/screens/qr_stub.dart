// Este archivo es un stub para la versión web
// No implementa ninguna funcionalidad real de QR
import 'package:flutter/material.dart';

class QRView extends StatelessWidget {
  final Key? key;
  final Function(QRViewController) onQRViewCreated;
  final QrScannerOverlayShape? overlay;

  const QRView({
    this.key,
    required this.onQRViewCreated,
    this.overlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Center(
        child: Text(
          'QR Scanner no disponible en la versión web',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class QRViewController {
  void toggleFlash() {}
  void flipCamera() {}
  void pauseCamera() {}
  void resumeCamera() {}
  void dispose() {}

  Stream<Barcode> get scannedDataStream => 
    Stream.empty();
}

class Barcode {
  final String? code;
  Barcode(this.code);
}

class QrScannerOverlayShape {
  final double borderLength;
  final double borderWidth;
  final double borderRadius;
  final Color borderColor;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderLength = 40,
    this.borderWidth = 10,
    this.borderRadius = 10,
    required this.borderColor,
    required this.cutOutSize,
  });
}
