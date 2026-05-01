import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/models.dart';

/// Static elevation profile chart, drawn from pre-computed (distance, elevation)
/// samples. Optionally renders vertical tick lines at the cumulative distance
/// of each checkpoint along the path.
class ElevationProfile extends StatelessWidget {
  final List<ElevationSample> samples;
  final List<double>? checkpointMarkersKm;
  final Color color;
  final double height;

  const ElevationProfile({
    super.key,
    required this.samples,
    this.checkpointMarkersKm,
    this.color = const Color(0xFF4CAF50),
    this.height = 110,
  });

  @override
  Widget build(BuildContext context) {
    if (samples.length < 2) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'Elevation data unavailable',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
      );
    }
    final minE = samples.map((s) => s.elevationM).reduce(math.min);
    final maxE = samples.map((s) => s.elevationM).reduce(math.max);
    final totalKm = samples.last.distanceKm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _ProfilePainter(
              samples: samples,
              markers: checkpointMarkersKm ?? const [],
              color: color,
              minElev: minE,
              maxElev: maxE,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              const Text('0 km',
                  style: TextStyle(color: Colors.white38, fontSize: 10)),
              const Spacer(),
              Text('${totalKm.toStringAsFixed(0)} km',
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfilePainter extends CustomPainter {
  final List<ElevationSample> samples;
  final List<double> markers;
  final Color color;
  final double minElev;
  final double maxElev;

  _ProfilePainter({
    required this.samples,
    required this.markers,
    required this.color,
    required this.minElev,
    required this.maxElev,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;
    final totalKm = samples.last.distanceKm;
    if (totalKm <= 0) return;

    final range = math.max(10.0, maxElev - minElev);
    final padMin = minElev - range * 0.08;
    final padMax = maxElev + range * 0.08;
    final padRange = padMax - padMin;

    double x(double km) => size.width * (km / totalKm);
    double y(double e) => size.height * (1 - (e - padMin) / padRange);

    // Filled gradient under the line
    final fillPath = ui.Path()..moveTo(0, size.height);
    fillPath.lineTo(x(samples.first.distanceKm), y(samples.first.elevationM));
    for (final s in samples) {
      fillPath.lineTo(x(s.distanceKm), y(s.elevationM));
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [
          color.withValues(alpha: 0.45),
          color.withValues(alpha: 0.04),
        ],
      );
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePath = ui.Path()
      ..moveTo(x(samples.first.distanceKm), y(samples.first.elevationM));
    for (int i = 1; i < samples.length; i++) {
      linePath.lineTo(x(samples[i].distanceKm), y(samples[i].elevationM));
    }
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Checkpoint markers (vertical dashed-ish ticks)
    final markerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    for (final km in markers) {
      if (km < 0 || km > totalKm) continue;
      final mx = x(km);
      // Dashed vertical line
      const dash = 3.0, gap = 3.0;
      double cy = 0;
      while (cy < size.height) {
        canvas.drawLine(Offset(mx, cy), Offset(mx, cy + dash), markerPaint);
        cy += dash + gap;
      }
    }

    // Min / max labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    void label(String text, Offset pos, {Color? c}) {
      tp.text = TextSpan(
        text: text,
        style: TextStyle(
          color: c ?? Colors.white60,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      );
      tp.layout();
      tp.paint(canvas, pos);
    }

    label('${maxElev.round()} m', const Offset(2, 0));
    label('${minElev.round()} m',
        Offset(2, size.height - 12), c: Colors.white38);
  }

  @override
  bool shouldRepaint(_ProfilePainter old) =>
      old.samples != samples || old.markers != markers || old.color != color;
}
