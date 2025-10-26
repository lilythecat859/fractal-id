// lib/id_to_image.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_io/io.dart';

abstract class IdToImage {
  /// Public API: address -> PNG bytes (deterministic)
  static Future<Uint8List> addressToPng(String address) async {
    final seed = _seedFor(address);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const size = 400.0;
    _FractalRenderer.render(canvas, size, seed);
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    return png!.buffer.asUint8List();
  }

  /// Save PNG to gallery / downloads depending on platform
  static Future<void> savePng(Uint8List bytes) async {
    if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/fractal_id.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)]);
    } else {
      // desktop / web: trigger browser download
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrl(blob);
      final anchor = html.AnchorElement(href: url)
        ..download = 'fractal_id.png'
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  /// Deterministic seed from address
  static int _seedFor(String address) {
    final norm = address.trim().toLowerCase().replaceAll(' ', '');
    final hash = sha256.convert(utf8.encode(norm));
    return hash.bytes.fold<int>(0, (a, b) => a * 256 + b);
  }
}

/// Simple deterministic fractal flame approximation
class _FractalRenderer {
  static void render(ui.Canvas canvas, double size, int seed) {
    final rng = Random(seed);
    final paint = ui.Paint()
      ..strokeWidth = 0.8
      ..style = ui.PaintingStyle.stroke;
    final colors = <Color>[
      Colors.cyanAccent,
      Colors.purpleAccent,
      Colors.pinkAccent,
      Colors.yellowAccent,
    ];
    const steps = 25000;
    double x = 0, y = 0;
    for (int i = 0; i < steps; i++) {
      final r = rng.nextDouble();
      double nx = 0, ny = 0;
      if (r < 0.33) {
        nx = 0;
        ny = 0.16 * y;
      } else if (r < 0.66) {
        nx = 0.85 * x + 0.04 * y;
        ny = -0.04 * x + 0.85 * y + 1.6;
      } else {
        nx = 0.2 * x - 0.26 * y;
        ny = 0.23 * x + 0.22 * y + 1.6;
      }
      x = nx;
      y = ny;
      final px = size * 0.5 + x * size * 0.15;
      final py = size - 1 - (y * size * 0.08);
      paint.color = colors[rng.nextInt(colors.length)].withOpacity(0.55);
      canvas.drawCircle(Offset(px, py), 0.7, paint);
    }
  }
}
