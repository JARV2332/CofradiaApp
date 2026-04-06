import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<StatefulWidget> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _flashOn = false;
  bool _frontCamera = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () async {
              if (controller != null) {
                await controller!.toggleFlash();
                setState(() {
                  _flashOn = !_flashOn;
                });
              }
            },
          ),
          IconButton(
            icon: Icon(_frontCamera ? Icons.camera_front : Icons.camera_rear),
            onPressed: () async {
              if (controller != null) {
                await controller!.flipCamera();
                setState(() {
                  _frontCamera = !_frontCamera;
                });
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.deepPurple,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: MediaQuery.of(context).size.width * 0.8,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.black54,
              child: const Text(
                'Coloca el código QR dentro del marco para escanearlo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null) {
        controller.pauseCamera();
        _mostrarResultadoDialogo(scanData.code!);
      }
    });
  }

  void _mostrarResultadoDialogo(String code) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Código QR Escaneado'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Contenido: $code'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller?.resumeCamera();
                Navigator.of(context).pop();
              },
              child: const Text('Escanear Otro'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Finalizar'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple,
              ),
            ),
          ],
        );
      },
    );
  }
}
