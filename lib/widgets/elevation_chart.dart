import 'package:flutter/material.dart';
import '../providers/ride_recorder_provider.dart';

/// Live elevation profile drawn with CustomPainter — no external dependencies.
class ElevationChart extends StatelessWidget {
  final List<TrackPoint> points;
  final double? currentElevationM;

  const ElevationChart({
    super.key,
    required this.points,
    this.currentElevationM,
  });

  @override
  Widget build(BuildContext context) {
    // Need at least 2 points with elevation data to draw
    final elevPoints =
        points.where((p) => p.elevationM != null).toList();

    if (elevPoints.length < 2) {
      return _WaitingForData(currentElevationM: currentElevationM);
    }

    final elevations = elevPoints.map((p) => p.elevationM!).toList();
    final minElev = elevations.reduce((a, b) => a < b ? a : b);
    final maxElev = elevations.reduce((a, b) => a > b ? a : b);
    final current = currentElevationM ?? elevations.last;

    // Elevation gain (sum of all positive climbs)
    double gain = 0;
    for (int i = 1; i < elevations.length; i++) {
      final diff = elevations[i] - elevations[i - 1];
      if (diff > 0) gain += diff;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.terrain, color: Color(0xFF4CAF50), size: 14),
              const SizedBox(width: 6),
              const Text(
                'Elevation',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              _ElevStat(label: 'Now', value: '${current.round()}m'),
              const SizedBox(width: 12),
              _ElevStat(label: '▲ Gain', value: '+${gain.round()}m',
                  color: const Color(0xFF4CAF50)),
              const SizedBox(width: 12),
              _ElevStat(label: 'Min', value: '${minElev.round()}m'),
              const SizedBox(width: 12),
              _ElevStat(label: 'Max', value: '${maxElev.round()}m'),
            ],
          ),
        ),
        // Chart
        SizedBox(
          height: 60,
          child: CustomPaint(
            painter: _ElevationPainter(
              elevations: elevations,
              minElev: minElev,
              maxElev: maxElev,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

class _ElevStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ElevStat({
    required this.label,
    required this.value,
    this.color = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 9)),
      ],
    );
  }
}

class _WaitingForData extends StatelessWidget {
  final double? currentElevationM;

  const _WaitingForData({this.currentElevationM});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.terrain, color: Colors.white38, size: 14),
          const SizedBox(width: 6),
          const Text(
            'Elevation',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const Spacer(),
          if (currentElevationM != null)
            Text(
              '${currentElevationM!.round()} m',
              style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            )
          else
            const Text(
              'Collecting data…',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _ElevationPainter extends CustomPainter {
  final List<double> elevations;
  final double minElev;
  final double maxElev;

  const _ElevationPainter({
    required this.elevations,
    required this.minElev,
    required this.maxElev,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (elevations.length < 2) return;

    // Give a small padding so flat sections still show
    final range = (maxElev - minElev).clamp(10.0, double.infinity);
    final padMin = minElev - range * 0.1;
    final padMax = maxElev + range * 0.1;
    final padRange = padMax - padMin;

    double xOf(int i) => size.width * i / (elevations.length - 1);
    double yOf(double elev) =>
        size.height * (1 - (elev - padMin) / padRange);

    final path = Path()..moveTo(xOf(0), yOf(elevations[0]));
    for (int i = 1; i < elevations.length; i++) {
      path.lineTo(xOf(i), yOf(elevations[i]));
    }

    // Filled area
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF4CAF50).withValues(alpha: 0.5),
          const Color(0xFF4CAF50).withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // Current position dot
    final lastX = xOf(elevations.length - 1);
    final lastY = yOf(elevations.last);
    canvas.drawCircle(
      Offset(lastX, lastY),
      4,
      Paint()..color = const Color(0xFFFC4C02),
    );
    canvas.drawCircle(
      Offset(lastX, lastY),
      2,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_ElevationPainter old) =>
      old.elevations.length != elevations.length ||
      (elevations.isNotEmpty &&
          old.elevations.last != elevations.last);
}
