import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/passport_provider.dart';
import '../providers/paths_provider.dart';
import 'map_screen.dart';
import 'checkpoint_detail_screen.dart';

class PathDetailScreen extends StatelessWidget {
  final int pathId;

  const PathDetailScreen({super.key, required this.pathId});

  @override
  Widget build(BuildContext context) {
    final path = context.read<PathsProvider>().pathById(pathId);
    if (path == null) {
      return const Scaffold(body: Center(child: Text('Path not found')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Consumer<PassportProvider>(
        builder: (context, passport, _) {
          final ids = path.checkpoints.map((c) => c.id).toList();
          final stamped = passport.stampedCount(ids);
          final complete = passport.pathComplete(ids);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: const Color(0xFF0D1117),
                iconTheme: const IconThemeData(color: Colors.white),
                title: Text(
                  path.shortName,
                  style: const TextStyle(color: Colors.white),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _PathMapPreview(path: path),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PathStats(path: path, stamped: stamped, complete: complete),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MapScreen(pathId: path.id),
                            ),
                          ),
                          icon: const Icon(Icons.navigation),
                          label: const Text('Start Riding'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Checkpoints',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final checkpoint = path.checkpoints[index];
                    final isStamped = passport.isStamped(checkpoint.id);
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: _CheckpointTile(
                        checkpoint: checkpoint,
                        index: index + 1,
                        isStamped: isStamped,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckpointDetailScreen(
                              checkpoint: checkpoint,
                              pathId: pathId,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: path.checkpoints.length,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PathMapPreview extends StatelessWidget {
  final CyclingPath path;

  const _PathMapPreview({required this.path});

  @override
  Widget build(BuildContext context) {
    final allCoords = path.routes.expand((r) => r.coordinates).toList();
    LatLngBounds? bounds;
    if (allCoords.length >= 2) {
      bounds = LatLngBounds.fromPoints(allCoords);
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: path.center,
        initialZoom: 9,
        initialCameraFit: bounds != null
            ? CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(20))
            : null,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.kpedal.app',
        ),
        for (final route in path.routes)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route.coordinates,
                color: const Color(0xFF4CAF50),
                strokeWidth: 3,
              ),
            ],
          ),
        MarkerLayer(
          markers: path.checkpoints.map((c) => Marker(
            point: c.position,
            width: 20,
            height: 20,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

class _PathStats extends StatelessWidget {
  final CyclingPath path;
  final int stamped;
  final bool complete;

  const _PathStats({
    required this.path,
    required this.stamped,
    required this.complete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (path.totalDistanceKm != null)
          _Stat(
            icon: Icons.straighten,
            value: '${path.totalDistanceKm!.round()} km',
            label: 'Total',
          ),
        const SizedBox(width: 12),
        _Stat(
          icon: Icons.where_to_vote,
          value: '${path.checkpoints.length}',
          label: 'Stamps',
        ),
        const SizedBox(width: 12),
        _Stat(
          icon: Icons.check_circle,
          value: '$stamped',
          label: 'Collected',
          highlight: complete,
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool highlight;

  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? const Color(0xFFFFD700) : const Color(0xFF4CAF50);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }
}

class _CheckpointTile extends StatelessWidget {
  final Checkpoint checkpoint;
  final int index;
  final bool isStamped;
  final VoidCallback onTap;

  const _CheckpointTile({
    required this.checkpoint,
    required this.index,
    required this.isStamped,
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
                ? const Color(0xFFFFD700).withOpacity(0.4)
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
                    ? const Color(0xFFFFD700).withOpacity(0.2)
                    : const Color(0xFFE53935).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isStamped
                    ? const Icon(Icons.check, color: Color(0xFFFFD700), size: 18)
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
                      color: isStamped ? const Color(0xFFFFD700) : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (isStamped)
                    const Text(
                      'Stamped',
                      style: TextStyle(color: Color(0xFFFFD700), fontSize: 11),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }
}
