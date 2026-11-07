// Minimal repro: on Windows with fractional display scale (125%), the page
// content below is rasterized as if devicePixelRatio were 1.0:
//
//  - the striped CustomPaint renders with a 24 device-px period instead of 30
//    (24 logical px period taken as device px), and stops ~20% short of the
//    bottom of the window;
//  - the BackdropFilter "glass" card paints only the top ~79% of its layout
//    height (68 logical px -> ~54 device px), leaving a hard horizontal edge
//    where the paint stops.
//
// Broken: 3.47.7-candidate.0 (engine deb287481e). Correct: stable 3.44.4
// (engine a10d8ac38d). Both Impeller and Skia are affected.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

void main() => runApp(const ReproApp());

class ReproApp extends StatelessWidget {
  const ReproApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      home: const ReproPage(),
    );
  }
}

class ReproPage extends StatelessWidget {
  const ReproPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // High-contrast stripes: 12 logical px teal + 12 logical px white.
          // At 125% scale the teal band should be 15 device px wide.
          const Positioned.fill(child: CustomPaint(painter: _StripePainter())),
          // A glass card: ClipRRect > BackdropFilter > gradient DecoratedBox.
          Positioned(
            top: 120,
            left: 180,
            width: 730,
            height: 68,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.38),
                        const Color(0xFFF4F8FC).withValues(alpha: 0.49),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  const _StripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF14B8A6);
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 12, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
