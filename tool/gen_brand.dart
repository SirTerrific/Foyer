// Generates the Foyer launcher icons and banner.
// Run from the project root:  flutter test tool/gen_brand.dart
// It is a "test" only because flutter_test gives headless access to dart:ui.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _bg = Color(0xFF1C1917);
const _amber = Color(0xFFF59E0B);
const _terracotta = Color(0xFFEA580C);
const _cream = Color(0xFFFDF6EC);

// Logo lives in a 52x52 box; the visible shape spans x 8..44, y 9..43.
void _drawLogo(Canvas canvas, {required double cx, required double cy, required double scale}) {
  canvas.save();
  canvas.translate(cx - 26 * scale, cy - 26 * scale);
  canvas.scale(scale);

  final house = Path()
    ..moveTo(8, 24)
    ..lineTo(26, 9)
    ..lineTo(44, 24)
    ..lineTo(44, 43)
    ..lineTo(8, 43)
    ..close();
  canvas.drawPath(
    house,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeJoin = StrokeJoin.round
      ..color = _amber,
  );

  final flame = Path()
    ..moveTo(26, 39)
    ..relativeCubicTo(-5, 0, -7, -4, -5, -8)
    ..relativeCubicTo(1, 2, 3, 2, 3, 0)
    ..relativeCubicTo(0, -3, 2, -5, 5, -7)
    ..relativeCubicTo(-1, 4, 4, 6, 3, 10)
    ..relativeCubicTo(-1, 3, -3, 5, -6, 5)
    ..close();
  canvas.drawPath(flame, Paint()..color = _terracotta);
  canvas.restore();
}

Future<void> _save(String path, int w, int h, void Function(Canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble())));
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path)..createSync(recursive: true);
  file.writeAsBytesSync(data!.buffer.asUint8List());
}

void main() {
  testWidgets('generate Foyer brand assets', (tester) async {
    await tester.runAsync(() async {
      final font = FontLoader('Roboto')
        ..addFont(Future.value(
            ByteData.sublistView(File('${Platform.environment['FLUTTER_ROOT'] ?? 'D:/Claude/flutter-3.41.9'}/bin/cache/artifacts/material_fonts/roboto-bold.ttf')
                .readAsBytesSync())));
      await font.load();

      const res = 'android/app/src/main/res';

      // Square icon (legacy launcher icon + About dialog): dark background, logo ~60% wide.
      Future<void> square(String path, int s) => _save(path, s, s, (c) {
            c.drawRect(Rect.fromLTWH(0, 0, s.toDouble(), s.toDouble()), Paint()..color = _bg);
            _drawLogo(c, cx: s / 2, cy: s / 2, scale: 0.62 * s / 36);
          });
      await square('assets/icon.png', 512);
      const legacy = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
      for (final e in legacy.entries) {
        await square('$res/mipmap-${e.key}/ic_launcher.png', e.value);
      }

      // Adaptive foreground: transparent, logo kept inside the 66/108 safe zone.
      const fg = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432};
      for (final e in fg.entries) {
        await _save('$res/drawable-${e.key}/ic_launcher_foreground.png', e.value, e.value,
            (c) => _drawLogo(c, cx: e.value / 2, cy: e.value / 2, scale: 0.48 * e.value / 36));
      }

      // TV banner 320x180: logo + wordmark, centered as a group.
      Future<void> banner(String path) => _save(path, 320, 180, (c) {
            c.drawRect(const Rect.fromLTWH(0, 0, 320, 180), Paint()..color = _bg);
            final tp = TextPainter(
              text: const TextSpan(
                  text: 'Foyer',
                  style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold, fontSize: 56, color: _cream, letterSpacing: 1)),
              textDirection: TextDirection.ltr,
            )..layout();
            const logoW = 80.0;
            const gap = 16.0;
            final total = logoW + gap + tp.width;
            final left = (320 - total) / 2;
            _drawLogo(c, cx: left + logoW / 2, cy: 90, scale: logoW / 36);
            tp.paint(c, Offset(left + logoW + gap, 90 - tp.height / 2));
          });
      await banner('$res/drawable/banner.png');
      await banner('$res/drawable-xhdpi/banner.png');
    });
  });
}
