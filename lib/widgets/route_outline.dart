import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';

/// Lightweight, tile-free preview of a path's shape.
/// Draws the concatenated route polyline plus start/end markers, fitted to the
/// available size with equirectangular projection.
class RouteOutline extends StatelessWidget {
  final CyclingPath path;
  final Color color;
  final double strokeWidth;
  final double markerRadius;
  final EdgeInsets padding;

  const RouteOutline({
    super.key,
    required this.path,
    required this.color,
    this.strokeWidth = 2.2,
    this.markerRadius = 4,
    this.padding = const EdgeInsets.all(6),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RouteOutlinePainter(
        path: path,
        color: color,
        strokeWidth: strokeWidth,
        markerRadius: markerRadius,
        padding: padding,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _RouteOutlinePainter extends CustomPainter {
  final CyclingPath path;
  final Color color;
  final double strokeWidth;
  final double markerRadius;
  final EdgeInsets padding;

  _RouteOutlinePainter({
    required this.path,
    required this.color,
    required this.strokeWidth,
    required this.markerRadius,
    required this.padding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final allPoints = <LatLng>[
      for (final seg in path.routes) ...seg.coordinates,
      for (final cp in path.checkpoints) cp.position,
    ];
    if (allPoints.isEmpty) return;

    double minLat = double.infinity, maxLat = -double.infinity;
    double minLng = double.infinity, maxLng = -double.infinity;
    for (final p in allPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final usable = Rect.fromLTWH(
      padding.left,
      padding.top,
      math.max(1.0, size.width - padding.horizontal),
      math.max(1.0, size.height - padding.vertical),
    );

    // Equirectangular projection: scale x by cos(midLat) so aspect feels right.
    final midLat = (minLat + maxLat) / 2;
    final cosLat = math.cos(midLat * math.pi / 180);
    final spanLng = math.max(1e-6, (maxLng - minLng) * cosLat);
    final spanLat = math.max(1e-6, maxLat - minLat);

    // Fit to usable rect preserving aspect ratio.
    final scale = math.min(usable.width / spanLng, usable.height / spanLat);
    final renderedW = spanLng * scale;
    final renderedH = spanLat * scale;
    final offsetX = usable.left + (usable.width - renderedW) / 2;
    final offsetY = usable.top + (usable.height - renderedH) / 2;

    Offset project(LatLng p) {
      final x = offsetX + (p.longitude - minLng) * cosLat * scale;
      // Flip Y: higher latitude → lower y (north up)
      final y = offsetY + (maxLat - p.latitude) * scale;
      return Offset(x, y);
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final seg in path.routes) {
      if (seg.coordinates.length < 2) continue;
      final pathToDraw = ui.Path();
      final first = project(seg.coordinates.first);
      pathToDraw.moveTo(first.dx, first.dy);
      for (int i = 1; i < seg.coordinates.length; i++) {
        final pt = project(seg.coordinates[i]);
        pathToDraw.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(pathToDraw, linePaint);
    }

    if (path.checkpoints.isNotEmpty) {
      final start = project(path.checkpoints.first.position);
      _drawMarker(canvas, start, const Color(0xFF4CAF50));
      if (path.checkpoints.length > 1) {
        final end = project(path.checkpoints.last.position);
        _drawMarker(canvas, end, const Color(0xFFE53935));
      }
    }
  }

  void _drawMarker(Canvas canvas, Offset center, Color fill) {
    canvas.drawCircle(
      center,
      markerRadius + 1,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      center,
      markerRadius,
      Paint()..color = fill,
    );
  }

  @override
  bool shouldRepaint(_RouteOutlinePainter old) =>
      old.path.id != path.id ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
