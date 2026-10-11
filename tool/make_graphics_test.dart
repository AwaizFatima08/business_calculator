// Renders the launcher icons and Play Store graphics in code, so they can be
// regenerated at any time (no image tools or generators needed).
//
//   flutter test tool/make_graphics_test.dart
//
// Writes:
//   android/app/src/main/res/drawable-*/ic_launcher_{foreground,background,monochrome}.png  adaptive icon
//   android/app/src/main/res/mipmap-*/ic_launcher.png                                        legacy icon
//   store-assets/icon-512.png                     Play icon (512x512, Play applies the mask)
//   store-assets/feature-graphic-1024x500.png     Play feature graphic
//   store-assets/screenshots/*.png                1080x1920 captioned phone screenshots, built from
//                                                 the renders in store-assets/raw/ (store_screens_test.dart)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const res = 'android/app/src/main/res';
const navy = Color(0xFF1F3A5F);
const navyDeep = Color(0xFF142740);
const green = Color(0xFF0E7A4F);
const paper = Color(0xFFFBFCF8);
const lcd = Color(0xFFE3F0E6);
const ink = Color(0xFF0F1419);
const daylight = Color(0xFFE9ECE6);

Future<void> save(String path, int w, int h, void Function(Canvas c, Size s) draw) async {
  final rec = ui.PictureRecorder();
  draw(Canvas(rec), Size(w.toDouble(), h.toDouble()));
  final img = await rec.endRecording().toImage(w, h);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

void iconBackground(Canvas c, Rect r) {
  c.drawRect(r, Paint()..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, [const Color(0xFF2B4D7A), navyDeep]));
}

/// The mark: a white calculator whose display shows a short tape (two lines
/// and a bold total), with a 3x3 key grid and a green "=" key. Drawn in [box].
/// With [mono] it is flat white with the details cut out (themed icons).
void mark(Canvas c, Rect box, {bool mono = false}) {
  Rect rel(double x, double y, double w, double h) =>
      Rect.fromLTWH(box.left + box.width * x, box.top + box.height * y, box.width * w, box.height * h);
  final u = box.width;
  final body = RRect.fromRectAndRadius(rel(0.16, 0.04, 0.68, 0.92), Radius.circular(u * 0.09));

  c.saveLayer(box.inflate(u * 0.2), Paint());
  if (!mono) {
    c.drawRRect(
      body.shift(Offset(0, u * 0.025)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, u * 0.02),
    );
  }
  c.drawRRect(body, Paint()..color = mono ? Colors.white : paper);

  final cut = Paint()..blendMode = BlendMode.clear;
  // Display with the tape.
  final screen = RRect.fromRectAndRadius(rel(0.24, 0.12, 0.52, 0.27), Radius.circular(u * 0.035));
  c.drawRRect(screen, mono ? cut : (Paint()..color = lcd));
  final linePaint = Paint()..color = mono ? Colors.white : const Color(0xFF7C8B84);
  c.drawRRect(RRect.fromRectAndRadius(rel(0.42, 0.155, 0.28, 0.035), Radius.circular(u * 0.02)), linePaint);
  c.drawRRect(RRect.fromRectAndRadius(rel(0.50, 0.215, 0.20, 0.035), Radius.circular(u * 0.02)), linePaint);
  c.drawRRect(
    RRect.fromRectAndRadius(rel(0.33, 0.29, 0.37, 0.065), Radius.circular(u * 0.03)),
    Paint()..color = mono ? Colors.white : ink,
  );

  // Keys: 3 columns x 3 rows, the bottom-right one is the tall "=" key.
  const kx = [0.24, 0.42, 0.60];
  const ky = [0.46, 0.60, 0.74];
  const k = 0.16;
  for (var row = 0; row < 3; row++) {
    for (var col = 0; col < 3; col++) {
      if (col == 2 && row >= 1) continue;
      final r = RRect.fromRectAndRadius(rel(kx[col], ky[row], k, 0.115), Radius.circular(u * 0.03));
      c.drawRRect(r, mono ? cut : (Paint()..color = col == 2 ? navy : const Color(0xFFD9E0E7)));
    }
  }
  final eq = RRect.fromRectAndRadius(rel(kx[2], ky[1], k, 0.255), Radius.circular(u * 0.03));
  c.drawRRect(eq, mono ? cut : (Paint()..color = green));
  // "=" bars on the green key.
  final bar = mono ? cut : (Paint()..color = Colors.white);
  c.drawRRect(RRect.fromRectAndRadius(rel(0.635, 0.79, 0.09, 0.022), Radius.circular(u * 0.01)), bar);
  c.drawRRect(RRect.fromRectAndRadius(rel(0.635, 0.83, 0.09, 0.022), Radius.circular(u * 0.01)), bar);
  c.restore();
}

Future<void> icons() async {
  const densities = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};
  for (final e in densities.entries) {
    final fg = (108 * e.value).round();
    // Adaptive layers: the mark sits in the 66dp safe zone of the 108dp canvas.
    Rect safe(Size s) => Rect.fromCenter(center: s.center(Offset.zero), width: s.width * 0.62, height: s.height * 0.62);
    await save('$res/drawable-${e.key}/ic_launcher_foreground.png', fg, fg, (c, s) => mark(c, safe(s)));
    await save('$res/drawable-${e.key}/ic_launcher_monochrome.png', fg, fg, (c, s) => mark(c, safe(s), mono: true));
    await save('$res/drawable-${e.key}/ic_launcher_background.png', fg, fg, (c, s) => iconBackground(c, Offset.zero & s));
    // Legacy square icon with rounded corners (pre-Android 8 launchers).
    final lg = (48 * e.value).round();
    await save('$res/mipmap-${e.key}/ic_launcher.png', lg, lg, (c, s) {
      c.clipRRect(RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(s.width * 0.22)));
      iconBackground(c, Offset.zero & s);
      mark(c, (Offset.zero & s).deflate(s.width * 0.12));
    });
  }
  File('$res/mipmap-anydpi-v26/ic_launcher.xml')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />
</adaptive-icon>
''');
  await save('store-assets/icon-512.png', 512, 512, (c, s) {
    iconBackground(c, Offset.zero & s);
    mark(c, (Offset.zero & s).deflate(s.width * 0.14));
  });
}

void text(
  Canvas c,
  String t,
  Offset at,
  TextStyle style, {
  double maxWidth = 2000,
  TextAlign align = TextAlign.left,
}) {
  final tp = TextPainter(
    text: TextSpan(text: t, style: style),
    textDirection: TextDirection.ltr,
    textAlign: align,
  )..layout(maxWidth: maxWidth);
  final dx = switch (align) {
    TextAlign.center => at.dx - tp.width / 2,
    TextAlign.right => at.dx - tp.width,
    _ => at.dx,
  };
  tp.paint(c, Offset(dx, at.dy));
}

const _font = 'Roboto';

Future<void> featureGraphic() async {
  await save('store-assets/feature-graphic-1024x500.png', 1024, 500, (c, s) {
    final r = Offset.zero & s;
    c.drawRect(r, Paint()..color = daylight);
    // Navy panel with the icon on the left.
    final panel = Rect.fromLTWH(0, 0, 380, 500);
    c.drawRect(panel, Paint()..shader = ui.Gradient.linear(panel.topLeft, panel.bottomRight, [const Color(0xFF2B4D7A), navyDeep]));
    mark(c, Rect.fromCenter(center: const Offset(190, 250), width: 300, height: 300));

    text(c, 'Business', const Offset(430, 62), const TextStyle(fontFamily: _font, fontWeight: FontWeight.w900, fontSize: 76, color: navy, letterSpacing: -1.5));
    text(c, 'Calculator', const Offset(430, 140), const TextStyle(fontFamily: _font, fontWeight: FontWeight.w900, fontSize: 76, color: navy, letterSpacing: -1.5));
    text(c, 'Tape  ·  M+ M− MR  ·  GT  ·  Tax', const Offset(434, 238), const TextStyle(fontFamily: _font, fontWeight: FontWeight.w600, fontSize: 30, color: green));

    // A strip of paper tape.
    final tape = RRect.fromRectAndRadius(const Rect.fromLTWH(434, 300, 540, 150), const Radius.circular(14));
    c.drawRRect(tape.shift(const Offset(0, 4)), Paint()..color = Colors.black12);
    c.drawRRect(tape, Paint()..color = paper);
    c.drawRRect(tape, Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFC4CABD)
      ..strokeWidth = 2);
    text(c, '2 + 2 + 2 + 2 + 2 + 2 − 6 × 4', const Offset(950, 322), const TextStyle(fontFamily: _font, fontSize: 32, color: Color(0xFF4A5560)), align: TextAlign.right);
    text(c, '= −12', const Offset(950, 368), const TextStyle(fontFamily: _font, fontWeight: FontWeight.w700, fontSize: 56, color: ink), align: TextAlign.right);
  });
}

Future<ui.Image> loadImage(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  return (await codec.getNextFrame()).image;
}

/// 1080x1920 (9:16) with a caption above a framed render of the app.
Future<void> screenshots() async {
  const shots = [
    ('01-expression', 'See every figure', 'The whole calculation stays on screen'),
    ('02-tax', 'Tax in one tap', 'TAX+ adds it, TAX− takes it out'),
    ('03-memory', 'Memory and Grand Total', 'M+  M−  MR  MC  and  GT'),
    ('04-tape', 'Your tape is saved', 'Reuse, copy or share past results'),
    ('05-settings', 'Set it up your way', 'Decimal places, tax rate, separators'),
  ];
  for (final (name, head, sub) in shots) {
    final raw = 'store-assets/raw/$name.png';
    if (!File(raw).existsSync()) continue;
    final img = await loadImage(raw);
    await save('store-assets/screenshots/$name.png', 1080, 1920, (c, s) {
      final r = Offset.zero & s;
      c.drawRect(r, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, [const Color(0xFF2B4D7A), navyDeep]));
      text(
        c,
        head,
        Offset(s.width / 2, 86),
        const TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, fontSize: 76, color: Colors.white),
        maxWidth: 1000,
        align: TextAlign.center,
      );
      text(
        c,
        sub,
        Offset(s.width / 2, 192),
        const TextStyle(fontFamily: _font, fontWeight: FontWeight.w500, fontSize: 40, color: Color(0xFF9FE3C2)),
        maxWidth: 1000,
        align: TextAlign.center,
      );
      // Phone frame, running off the bottom edge.
      const top = 300.0;
      final h = s.height - top + 60;
      final w = h * img.width / img.height;
      final frame = Rect.fromLTWH((s.width - w) / 2, top, w, h);
      final outer = RRect.fromRectAndRadius(frame.inflate(18), const Radius.circular(64));
      c.drawRRect(
        outer.shift(const Offset(0, 16)),
        Paint()
          ..color = Colors.black54
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
      );
      c.drawRRect(outer, Paint()..color = const Color(0xFF0B1320));
      c.save();
      c.clipRRect(RRect.fromRectAndRadius(frame, const Radius.circular(48)));
      c.drawImageRect(
        img,
        Offset.zero & Size(img.width.toDouble(), img.height.toDouble()),
        frame,
        Paint()..filterQuality = FilterQuality.high,
      );
      c.restore();
    });
  }
}

void main() {
  testWidgets('make graphics', (tester) async {
    await tester.runAsync(() async {
      const fonts = '/mnt/storage/projects/flutter/bin/cache/artifacts/material_fonts';
      final loader = FontLoader(_font);
      for (final f in ['Regular', 'Medium', 'Bold', 'Black']) {
        loader.addFont(Future.value(ByteData.sublistView(File('$fonts/Roboto-$f.ttf').readAsBytesSync())));
      }
      await loader.load();
      await icons();
      await featureGraphic();
      await screenshots();
    });
    expect(File('store-assets/icon-512.png').existsSync(), isTrue);
  });
}
