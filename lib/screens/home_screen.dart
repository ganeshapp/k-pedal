import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/passport_provider.dart';
import '../providers/paths_provider.dart';
import '../widgets/route_outline.dart';
import 'path_detail_screen.dart';
import 'passport_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Consumer2<PathsProvider, PassportProvider>(
        builder: (context, pathsProvider, passport, _) {
          if (pathsProvider.loading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            );
          }

          final paths = pathsProvider.paths;
          final totalCheckpoints = paths.fold<int>(
            0, (sum, p) => sum + p.checkpoints.length);
          final totalStamped = paths.fold<int>(
            0, (sum, p) => sum + passport.stampedCount(
              p.checkpoints.map((c) => c.id).toList()));

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: const Color(0xFF0D1117),
                flexibleSpace: FlexibleSpaceBar(
                  background: _Header(
                    totalStamped: totalStamped,
                    totalCheckpoints: totalCheckpoints,
                    completedPaths: paths.where((p) =>
                      passport.pathComplete(p.checkpoints.map((c) => c.id).toList())
                    ).length,
                    totalPaths: paths.length,
                  ),
                ),
                title: const Text(
                  'K-Pedal',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    tooltip: 'Travel Info',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.book, color: Colors.white),
                    tooltip: 'My Passport',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PassportScreen()),
                    ),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final path = paths[index];
                      final ids = path.checkpoints.map((c) => c.id).toList();
                      final stamped = passport.stampedCount(ids);
                      final complete = passport.pathComplete(ids);
                      return _PathCard(
                        path: path,
                        stamped: stamped,
                        complete: complete,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PathDetailScreen(pathId: path.id),
                          ),
                        ),
                      );
                    },
                    childCount: paths.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int totalStamped;
  final int totalCheckpoints;
  final int completedPaths;
  final int totalPaths;

  const _Header({
    required this.totalStamped,
    required this.totalCheckpoints,
    required this.completedPaths,
    required this.totalPaths,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A2A), Color(0xFF0D1117)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: _StatChip(
                  icon: Icons.military_tech,
                  value: '$completedPaths/$totalPaths',
                  label: 'Paths Done',
                  color: const Color(0xFFFFD700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatChip(
                  icon: Icons.where_to_vote,
                  value: '$totalStamped/$totalCheckpoints',
                  label: 'Stamps',
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              Text(label,
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  final CyclingPath path;
  final int stamped;
  final bool complete;
  final VoidCallback onTap;

  const _PathCard({
    required this.path,
    required this.stamped,
    required this.complete,
    required this.onTap,
  });

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

  Color get _color => _pathColors[(path.id - 1) % _pathColors.length];

  @override
  Widget build(BuildContext context) {
    final total = path.checkpoints.length;
    final progress = total > 0 ? stamped / total : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: complete ? const Color(0xFFFFD700) : _color.withOpacity(0.3),
            width: complete ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Route outline preview
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15)),
                      child: Container(
                        color: _color.withOpacity(0.06),
                        child: RouteOutline(
                          path: path,
                          color: _color,
                        ),
                      ),
                    ),
                  ),
                  if (complete)
                    const Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(Icons.military_tech,
                          color: Color(0xFFFFD700), size: 22),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path.shortName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (path.totalDistanceKm != null)
                    Text(
                      '${path.totalDistanceKm!.round()} km',
                      style: TextStyle(
                          color: _color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white12,
                      color: complete ? const Color(0xFFFFD700) : _color,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$stamped / $total stamps',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
