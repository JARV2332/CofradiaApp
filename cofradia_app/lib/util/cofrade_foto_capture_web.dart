import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Abre un diálogo con vista previa de la cámara (getUserMedia) y devuelve JPEG en memoria.
Future<Uint8List?> captureCofradePhotoWithWebCamera(BuildContext context) {
  return showDialog<Uint8List?>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (ctx) => const _WebCameraCaptureDialog(),
  );
}

class _WebCameraCaptureDialog extends StatefulWidget {
  const _WebCameraCaptureDialog();

  @override
  State<_WebCameraCaptureDialog> createState() => _WebCameraCaptureDialogState();
}

class _WebCameraCaptureDialogState extends State<_WebCameraCaptureDialog> {
  web.MediaStream? _stream;
  String? _viewType;
  web.HTMLVideoElement? _videoEl;
  bool _opening = true;
  String? _error;
  bool _readyToShoot = false;

  @override
  void initState() {
    super.initState();
    _openCamera();
  }

  Future<void> _openCamera() async {
    try {
      final md = web.window.navigator.mediaDevices;
      if (md == null) {
        setState(() {
          _opening = false;
          _error = 'Este navegador no permite acceso a la cámara.';
        });
        return;
      }
      final stream =
          await md.getUserMedia(web.MediaStreamConstraints(video: true.toJS)).toDart;
      if (!mounted) {
        _stopStream(stream);
        return;
      }
      final vt =
          'cofrade-cam-${identityHashCode(this)}-${DateTime.now().microsecondsSinceEpoch}';
      ui_web.platformViewRegistry.registerViewFactory(vt, (int _) {
        final video = web.HTMLVideoElement()
          ..autoplay = true
          ..muted = true
          ..setAttribute('playsinline', 'true')
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.setProperty('object-fit', 'cover')
          ..srcObject = stream;
        _videoEl = video;
        unawaited(video.play().toDart);
        return video;
      });
      setState(() {
        _stream = stream;
        _viewType = vt;
        _opening = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _readyToShoot = true);
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _opening = false;
          _error =
              'No se pudo usar la cámara. Permite el permiso en el navegador o elige un archivo con “Elegir imagen”. ($e)';
        });
      }
    }
  }

  void _stopStream(web.MediaStream? s) {
    if (s == null) return;
    for (final t in s.getTracks().toDart) {
      t.stop();
    }
  }

  @override
  void dispose() {
    _stopStream(_stream);
    super.dispose();
  }

  void _capture() {
    final video = _videoEl;
    if (video == null) return;
    final w = video.videoWidth;
    final h = video.videoHeight;
    if (w == 0 || h == 0) return;
    final canvas = web.HTMLCanvasElement()
      ..width = w
      ..height = h;
    canvas.context2D.drawImage(video, 0, 0, w, h);
    final dataUrl = canvas.toDataUrl('image/jpeg', 0.9);
    final i = dataUrl.indexOf(',');
    if (i < 0) return;
    final bytes = base64Decode(dataUrl.substring(i + 1));
    _stopStream(_stream);
    _stream = null;
    if (mounted) Navigator.of(context).pop(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tomar foto'),
      content: SizedBox(
        width: 320,
        height: 280,
        child: _opening
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? SingleChildScrollView(
                    child: Text(_error!, style: const TextStyle(fontSize: 13)),
                  )
                : _viewType == null
                    ? const Center(child: Text('Sin vista de cámara'))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: HtmlElementView(viewType: _viewType!),
                      ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _stopStream(_stream);
            Navigator.of(context).pop(null);
          },
          child: const Text('Cancelar'),
        ),
        if (!_opening && _error == null)
          FilledButton(
            onPressed: _readyToShoot ? _capture : null,
            child: const Text('Capturar'),
          ),
      ],
    );
  }
}
