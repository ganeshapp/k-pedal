import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/passport_provider.dart';
import '../providers/paths_provider.dart';
import '../widgets/elevation_profile.dart';
import 'checkpoint_detail_screen.dart';

class PathDetailScreen extends StatelessWidget {
  final int pathId;

  const PathDetailScreen({super.key, required this.pathId});

  static const _pathColors = [
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF5722),
    Color(0xFF607D8B),
    Color(0xFF8BC34A),
    Color(0xFFFFC107),
  ];

  @override
  Widget build(BuildContext context) {
    final path = context.read<PathsProvider>().pathById(pathId);
    if (path == null) {
      return const Scaffold(body: Center(child: Text('Path not found')));
    }
    final color = _pathColors[(path.id - 1) % _pathColors.length];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          path.shortName,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Consumer<PassportProvider>(
        builder: (context, passport, _) {
          final ids = path.checkpoints.map((c) => c.id).toList();
          final stamped = passport.stampedCount(ids);
          final complete = passport.pathComplete(ids);

          // Cumulative km of each checkpoint along the route, derived from legs.
          final cumulativeKm = _cumulativeCheckpointKm(path);

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _PathMap(path: path, color: color, passport: passport),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _StartEndStrip(path: path),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _StatsRow(
                  path: path,
                  color: color,
                  stamped: stamped,
                  complete: complete,
                ),
              ),
              if (path.overallElevation.length >= 2) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.terrain,
                          color: Color(0xFF4CAF50), size: 16),
                      const SizedBox(width: 6),
                      const Text('Elevation Profile',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const Spacer(),
                      Text('+${path.elevationGainM.round()}m',
                          style: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text('-${path.elevationLossM.round()}m',
                          style: const TextStyle(
                              color: Color(0xFFE53935),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
                  child: ElevationProfile(
                    samples: path.overallElevation,
                    checkpointMarkersKm: cumulativeKm,
                    color: color,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Checkpoints',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ..._buildCheckpointList(
                  context, path, passport, color, cumulativeKm),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  List<double> _cumulativeCheckpointKm(CyclingPath path) {
    final out = <double>[0.0];
    for (final leg in path.legs) {
      out.add(out.last + leg.distanceKm);
    }
    // If legs were not present, return one zero per checkpoint as fallback.
    while (out.length < path.checkpoints.length) {
      out.add(out.last);
    }
    return out;
  }

  List<Widget> _buildCheckpointList(
    BuildContext context,
    CyclingPath path,
    PassportProvider passport,
    Color color,
    List<double> cumulativeKm,
  ) {
    final widgets = <Widget>[];
    for (int i = 0; i < path.checkpoints.length; i++) {
      final c = path.checkpoints[i];
      final isStamped = passport.isStamped(c.id);
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: _CheckpointTile(
            checkpoint: c,
            index: i + 1,
            isStamped: isStamped,
            cumulativeKm: i < cumulativeKm.length ? cumulativeKm[i] : null,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CheckpointDetailScreen(
                  checkpoint: c,
                  pathId: path.id,
                ),
              ),
            ),
          ),
        ),
      );
      // Leg connector to the next checkpoint
      if (i < path.legs.length) {
        widgets.add(_LegConnector(leg: path.legs[i]));
      }
    }
    return widgets;
  }
}

// ── Embedded map ─────────────────────────────────────────────────────────────

class _PathMap extends StatelessWidget {
  final CyclingPath path;
  final Color color;
  final PassportProvider passport;

  const _PathMap({
    required this.path,
    required this.color,
    required this.passport,
  });

  LatLngBounds _bounds() {
    double minLat = double.infinity, maxLat = -double.infinity;
    double minLng = double.infinity, maxLng = -double.infinity;
    void include(LatLng p) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    for (final c in path.checkpoints) {
      include(c.position);
    }
    for (final r in path.routes) {
      for (final p in r.coordinates) {
        include(p);
      }
    }
    if (minLat == double.infinity) {
      minLat = maxLat = path.center.latitude;
      minLng = maxLng = path.center.longitude;
    }
    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  @override
  Widget build(BuildContext context) {
    final bounds = _bounds();

    return SizedBox(
      height: 280,
      child: FlutterMap(
        options: MapOptions(
          initialCameraFit: CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(40),
          ),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.pinchZoom |
                InteractiveFlag.drag |
                InteractiveFlag.doubleTapZoom,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.kpedal.app',
          ),
          PolylineLayer(
            polylines: path.routes
                .where((r) => r.coordinates.length >= 2)
                .map((r) => Polyline(
                      points: r.coordinates,
                      color: color,
                      strokeWidth: 3.5,
                    ))
                .toList(),
          ),
          MarkerLayer(
            markers: [
              for (int i = 0; i < path.checkpoints.length; i++)
                Marker(
                  point: path.checkpoints[i].position,
                  width: 28,
                  height: 28,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckpointDetailScreen(
                          checkpoint: path.checkpoints[i],
                          pathId: path.id,
                        ),
                      ),
                    ),
                    child: _CheckpointPin(
                      number: i + 1,
                      isStamped: passport.isStamped(path.checkpoints[i].id),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckpointPin extends StatelessWidget {
  final int number;
  final bool isStamped;

  const _CheckpointPin({required this.number, required this.isStamped});

  @override
  Widget build(BuildContext context) {
    final color =
        isStamped ? const Color(0xFFFFD700) : const Color(0xFFE53935);
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ── Start / End strip ────────────────────────────────────────────────────────

class _StartEndStrip extends StatelessWidget {
  final CyclingPath path;
  const _StartEndStrip({required this.path});

  @override
  Widget build(BuildContext context) {
    final start = path.checkpoints.isNotEmpty ? path.checkpoints.first.name : '—';
    final end =
        path.checkpoints.length > 1 ? path.checkpoints.last.name : '—';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trip_origin,
                  color: Color(0xFF4CAF50), size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(start,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.flag, color: Color(0xFFE53935), size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(end,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final CyclingPath path;
  final Color color;
  final int stamped;
  final bool complete;

  const _StatsRow({
    required this.path,
    required this.color,
    required this.stamped,
    required this.complete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (path.totalDistanceKm != null)
          Expanded(
            child: _Stat(
              icon: Icons.straighten,
              value: '${path.totalDistanceKm!.round()}',
              unit: 'km',
              label: 'Total',
              color: color,
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: _Stat(
            icon: Icons.where_to_vote,
            value: '${path.checkpoints.length}',
            unit: '',
            label: 'Stamps',
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Stat(
            icon: Icons.check_circle,
            value: '$stamped',
            unit: '',
            label: 'Collected',
            color: complete ? const Color(0xFFFFD700) : const Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;
  final Color color;

  const _Stat({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(unit,
                      style: TextStyle(
                          color: color.withValues(alpha: 0.7), fontSize: 10)),
                ),
              ],
            ],
          ),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Checkpoint list ──────────────────────────────────────────────────────────

class _CheckpointTile extends StatelessWidget {
  final Checkpoint checkpoint;
  final int index;
  final bool isStamped;
  final double? cumulativeKm;
  final VoidCallback onTap;

  const _CheckpointTile({
    required this.checkpoint,
    required this.index,
    required this.isStamped,
    required this.cumulativeKm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isStamped
                ? const Color(0xFFFFD700).withValues(alpha: 0.4)
                : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isStamped
                    ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                    : const Color(0xFFE53935).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isStamped
                    ? const Icon(Icons.check,
                        color: Color(0xFFFFD700), size: 18)
                    : Text(
                        '$index',
                        style: const TextStyle(
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    checkpoint.name,
                    style: TextStyle(
                      color:
                          isStamped ? const Color(0xFFFFD700) : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (cumulativeKm != null)
                    Text(
                      '${cumulativeKm!.toStringAsFixed(1)} km from start',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }
}

class _LegConnector extends StatelessWidget {
  final CheckpointLeg leg;

  const _LegConnector({required this.leg});

  @override
  Widget build(BuildContext context) {
    final approx = !leg.isAlongRoute;
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 0, 16, 0),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 22,
            color: Colors.white24,
          ),
          const SizedBox(width: 14),
          Icon(
            approx ? Icons.straighten : Icons.directions_bike,
            color: Colors.white38,
            size: 12,
          ),
          const SizedBox(width: 6),
          Text(
            '${leg.distanceKm.toStringAsFixed(1)} km'
            '${approx ? '  (approx)' : ''}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
