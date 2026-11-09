// Generates the Foyer launcher icons and banner.
// Run from the project root:  flutter test tool/gen_brand.dart
// It is a "test" only because flutter_test gives headless access to dart:ui.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Palette: night brown background, ember glow, amber-to-terracotta house, golden flame.
const _night = Color(0xFF140D0A);
const _ember = Color(0xFF7C2D12);
const _gold = Color(0xFFFCD34D);
const _amber = Color(0xFFF59E0B);
const _terracotta = Color(0xFFEA580C);
const _hearth = Color(0xFF2A130B);
const _flameOuter = Color(0xFFF97316);
const _flameCore = Color(0xFFFEF3C7);
const _cream = Color(0xFFFDF6EC);

/// Warm radial glow, brighter just below the center where the hearth sits.
void _drawBackground(Canvas canvas, Rect rect) {
  canvas.drawRect(rect, Paint()..color = _night);
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.radial(
        Offset(rect.center.dx, rect.top + rect.height * 0.58),
        rect.shortestSide * 0.62,
        [_ember, _ember.withValues(alpha: 0.35), _night.withValues(alpha: 0)],
        [0, 0.55, 1],
      ),
  );
}

// Logo lives in a 52x52 box; the visible shape spans x 6..46, y 7..45.
void _drawLogo(Canvas canvas, {required double cx, required double cy, required double scale}) {
  canvas.save();
  canvas.translate(cx - 26 * scale, cy - 26 * scale);
  canvas.scale(scale);

  final bodyShader = ui.Gradient.linear(const Offset(26, 7), const Offset(26, 45), [_gold, _amber, _terracotta], [0, 0.45, 1]);

  // Soft shadow under the house so it lifts off the background.
  final outline = Path()
    ..moveTo(7, 24)
    ..lineTo(26, 8.5)
    ..lineTo(45, 24)
    ..lineTo(45, 44)
    ..lineTo(7, 44)
    ..close();
  final chimney = Path()..addRect(const Rect.fromLTWH(34.5, 10, 5, 10));
  final silhouette = Path.combine(PathOperation.union, outline, chimney);
  canvas.drawPath(
    silhouette.shift(const Offset(0, 1.6)),
    Paint()
      ..color = const Color(0x66000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
  );

  // Hearth arch carved out of the house front.
  final arch = Path()
    ..moveTo(17, 46)
    ..lineTo(17, 34)
    ..arcToPoint(const Offset(35, 34), radius: const Radius.circular(9))
    ..lineTo(35, 46)
    ..close();
  final body = Path.combine(PathOperation.difference, silhouette, arch);
  canvas.drawPath(body, Paint()..shader = bodyShader);
  // Same path stroked with round joins: rounds every corner of the fill.
  canvas.drawPath(
    body,
    Paint()
      ..shader = bodyShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round,
  );

  // Inside of the hearth: dark, lit from below by the fire.
  final inner = Path()
    ..moveTo(18.2, 44)
    ..lineTo(18.2, 34)
    ..arcToPoint(const Offset(33.8, 34), radius: const Radius.circular(7.8))
    ..lineTo(33.8, 44)
    ..close();
  canvas.drawPath(
    inner,
    Paint()
      ..shader = ui.Gradient.linear(
          const Offset(26, 26), const Offset(26, 44), [_hearth, const Color(0xFF5A2410)]),
  );

  // Fire glow.
  canvas.drawCircle(
    const Offset(26, 39),
    7,
    Paint()
      ..color = _flameOuter.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
  );

  Path flame(double s) {
    // Teardrop with a flick to the left, anchored on its base point (26, 43).
    final p = Path()
      ..moveTo(26, 43)
      ..cubicTo(21.6, 43, 20.2, 39.4, 21.9, 36.2)
      ..cubicTo(23, 34.1, 25.3, 32.8, 25.4, 28.6)
      ..cubicTo(28.8, 30.9, 31.6, 34.4, 30.9, 38.2)
      ..cubicTo(30.5, 41, 28.6, 43, 26, 43)
      ..close();
    final m = Matrix4.identity()
      ..translateByDouble(26, 43, 0, 1)
      ..scaleByDouble(s, s, 1, 1)
      ..translateByDouble(-26, -43, 0, 1);
    return p.transform(m.storage);
  }

  canvas.drawPath(
    flame(1),
    Paint()..shader = ui.Gradient.linear(const Offset(26, 28), const Offset(26, 43), [_amber, _flameOuter, _terracotta], [0, 0.5, 1]),
  );
  canvas.drawPath(
    flame(0.55),
    Paint()..shader = ui.Gradient.linear(const Offset(26, 35), const Offset(26, 43), [_flameCore, _gold]),
  );

  // Log under the fire.
  canvas.drawRRect(
    RRect.fromRectAndRadius(const Rect.fromLTWH(20.5, 42.6, 11, 1.8), const Radius.circular(0.9)),
    Paint()..color = const Color(0xFF3B1A0E),
  );

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

      // Square icon (legacy launcher icon + About dialog), corners rounded like the system mask.
      Future<void> square(String path, int s, {bool rounded = true}) => _save(path, s, s, (c) {
            final rect = Rect.fromLTWH(0, 0, s.toDouble(), s.toDouble());
            if (rounded) c.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(s * 0.22)));
            _drawBackground(c, rect);
            _drawLogo(c, cx: s / 2, cy: s / 2, scale: 0.7 * s / 40);
          });
      await square('assets/icon.png', 512);
      const legacy = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
      for (final e in legacy.entries) {
        await square('$res/mipmap-${e.key}/ic_launcher.png', e.value);
      }

      // Adaptive icon: glow background layer + transparent foreground inside the 66/108 safe zone.
      const adaptive = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432};
      for (final e in adaptive.entries) {
        final s = e.value.toDouble();
        await _save('$res/drawable-${e.key}/ic_launcher_background.png', e.value, e.value,
            (c) => _drawBackground(c, Rect.fromLTWH(0, 0, s, s)));
        await _save('$res/drawable-${e.key}/ic_launcher_foreground.png', e.value, e.value,
            (c) => _drawLogo(c, cx: s / 2, cy: s / 2, scale: 0.52 * s / 40));
      }

      // TV banner 320x180: logo + wordmark, centered as a group.
      Future<void> banner(String path) => _save(path, 320, 180, (c) {
            _drawBackground(c, const Rect.fromLTWH(0, 0, 320, 180));
            final tp = TextPainter(
              text: const TextSpan(
                  text: 'Foyer',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                    fontSize: 58,
                    color: _cream,
                    letterSpacing: 1.5,
                    shadows: [Shadow(color: Color(0x88000000), blurRadius: 6, offset: Offset(0, 2))],
                  )),
              textDirection: TextDirection.ltr,
            )..layout();
            const logoW = 92.0;
            const gap = 14.0;
            final total = logoW + gap + tp.width;
            final left = (320 - total) / 2;
            _drawLogo(c, cx: left + logoW / 2, cy: 90, scale: logoW / 40);
            tp.paint(c, Offset(left + logoW + gap, 90 - tp.height / 2));
          });
      await banner('$res/drawable/banner.png');
      await banner('$res/drawable-xhdpi/banner.png');
    });
  });
}
