import 'package:flutter/material.dart';
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
                expandedHeight: 220,
                pinned: true,
                backgroundColor: const Color(0xFF0D1117),
                iconTheme: const IconThemeData(color: Colors.white),
                title: Text(
                  path.shortName,
                  style: const TextStyle(color: Colors.white),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _PathHeader(path: path, complete: complete),
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
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

// ── Lightweight gradient header — no map tiles, instant render ───────────────

class _PathHeader extends StatelessWidget {
  final CyclingPath path;
  final bool complete;

  const _PathHeader({required this.path, required this.complete});

  static const _colors = [
    [Color(0xFF1A3A5C), Color(0xFF0D1117)],
    [Color(0xFF1A3A2A), Color(0xFF0D1117)],
    [Color(0xFF3A2A1A), Color(0xFF0D1117)],
    [Color(0xFF3A1A2A), Color(0xFF0D1117)],
    [Color(0xFF2A1A3A), Color(0xFF0D1117)],
    [Color(0xFF1A3A3A), Color(0xFF0D1117)],
    [Color(0xFF3A2A1A), Color(0xFF0D1117)],
    [Color(0xFF1A2A3A), Color(0xFF0D1117)],
    [Color(0xFF2A3A1A), Color(0xFF0D1117)],
    [Color(0xFF3A1A1A), Color(0xFF0D1117)],
  ];

  List<Color> get _gradient =>
      _colors[(path.id - 1) % _colors.length];

  @override
  Widget build(BuildContext context) {
    final start = path.checkpoints.isNotEmpty
        ? path.checkpoints.first.name
        : '—';
    final end = path.checkpoints.length > 1
        ? path.checkpoints.last.name
        : '—';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.pedal_bike, color: Colors.white54, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      path.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (complete)
                    const Icon(Icons.military_tech,
                        color: Color(0xFFFFD700), size: 28),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.trip_origin,
                      color: Color(0xFF4CAF50), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      start,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.flag, color: Color(0xFFE53935), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      end,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stats row ────────────────────────────────────────────────────────────────

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
    final color =
        highlight ? const Color(0xFFFFD700) : const Color(0xFF4CAF50);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

// ── Checkpoint list tile ─────────────────────────────────────────────────────

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
                  if (isStamped)
                    const Text(
                      'Stamped',
                      style:
                          TextStyle(color: Color(0xFFFFD700), fontSize: 11),
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
