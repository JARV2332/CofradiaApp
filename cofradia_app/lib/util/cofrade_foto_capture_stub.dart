import 'dart:typed_data';

import 'package:flutter/material.dart';

/// En plataformas que no son navegador, no aplica (usa [ImagePicker]).
Future<Uint8List?> captureCofradePhotoWithWebCamera(BuildContext context) async =>
    null;
