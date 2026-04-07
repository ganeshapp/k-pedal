import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/passport_provider.dart';
import '../providers/paths_provider.dart';
import 'path_detail_screen.dart';

class PassportScreen extends StatelessWidget {
  const PassportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'My Passport',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer2<PathsProvider, PassportProvider>(
        builder: (context, pathsProvider, passport, _) {
          final paths = pathsProvider.paths;
          final totalCheckpoints =
              paths.fold<int>(0, (s, p) => s + p.checkpoints.length);
          final totalStamped = paths.fold<int>(
            0,
            (s, p) => s + passport.stampedCount(
                  p.checkpoints.map((c) => c.id).toList()),
          );
          final completedPaths = paths
              .where((p) => passport.pathComplete(
                  p.checkpoints.map((c) => c.id).toList()))
              .length;
          final grandSlam = completedPaths == paths.length && paths.isNotEmpty;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Grand slam banner
                    if (grandSlam)
                      _GrandSlamBanner()
                    else
                      _ProgressHeader(
                        totalStamped: totalStamped,
                        totalCheckpoints: totalCheckpoints,
                        completedPaths: completedPaths,
                        totalPaths: paths.length,
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final path = paths[index];
                      return _PassportPage(
                        path: path,
                        passport: passport,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PathDetailScreen(pathId: path.id),
                          ),
                        ),
                      );
                    },
                    childCount: paths.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int totalStamped;
  final int totalCheckpoints;
  final int completedPaths;
  final int totalPaths;

  const _ProgressHeader({
    required this.totalStamped,
    required this.totalCheckpoints,
    required this.completedPaths,
    required this.totalPaths,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        totalCheckpoints > 0 ? totalStamped / totalCheckpoints : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Korea Cycling Passport',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Icon(Icons.book, color: Color(0xFF4CAF50)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _BigStat(
                value: '$totalStamped',
                label: 'Stamps',
                color: const Color(0xFFE53935),
              ),
              const SizedBox(width: 12),
              _BigStat(
                value: '$completedPaths',
                label: 'Paths Done',
                color: const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 12),
              _BigStat(
                value: '${(progress * 100).round()}%',
                label: 'Overall',
                color: const Color(0xFF2196F3),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white12,
              color: const Color(0xFF4CAF50),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$totalStamped / $totalCheckpoints checkpoints stamped across $totalPaths paths',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _BigStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 22)),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _GrandSlamBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B3F00), Color(0xFFD4A017), Color(0xFF7B3F00)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.military_tech, color: Colors.white, size: 56),
          SizedBox(height: 8),
          Text(
            'Korea Grand Slam!',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'You completed all cycling paths in Korea!',
            style: TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PassportPage extends StatelessWidget {
  final CyclingPath path;
  final PassportProvider passport;
  final VoidCallback onTap;

  const _PassportPage({
    required this.path,
    required this.passport,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ids = path.checkpoints.map((c) => c.id).toList();
    final stamped = passport.stampedCount(ids);
    final complete = passport.pathComplete(ids);
    final total = path.checkpoints.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: complete
                ? const Color(0xFFFFD700).withOpacity(0.5)
                : Colors.white12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        path.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (path.totalDistanceKm != null)
                        Text(
                          '${path.totalDistanceKm!.round()} km  •  $total checkpoints',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                if (complete)
                  const Icon(Icons.military_tech,
                      color: Color(0xFFFFD700), size: 28)
                else
                  Text(
                    '$stamped/$total',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Stamp grid
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: path.checkpoints.map((c) {
                final isStamped = passport.isStamped(c.id);
                return Tooltip(
                  message: c.name,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isStamped
                          ? const Color(0xFFE53935)
                          : const Color(0xFF0D1117),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isStamped
                            ? const Color(0xFFE53935)
                            : Colors.white12,
                      ),
                    ),
                    child: isStamped
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
