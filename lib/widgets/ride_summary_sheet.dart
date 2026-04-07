import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/ride_recorder_provider.dart';
import '../services/gpx_service.dart';

class RideSummarySheet extends StatefulWidget {
  final CompletedRide ride;
  final String? pathName;

  const RideSummarySheet({
    super.key,
    required this.ride,
    this.pathName,
  });

  static Future<void> show(
    BuildContext context,
    CompletedRide ride, {
    String? pathName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RideSummarySheet(ride: ride, pathName: pathName),
    );
  }

  @override
  State<RideSummarySheet> createState() => _RideSummarySheetState();
}

class _RideSummarySheetState extends State<RideSummarySheet> {
  bool _exporting = false;

  Future<void> _shareGpx() async {
    setState(() => _exporting = true);
    try {
      final file = await GpxService.saveGpx(
        widget.ride,
        pathName: widget.pathName,
      );
      final xfile = XFile(file.path, mimeType: 'application/gpx+xml');
      await Share.shareXFiles(
        [xfile],
        subject: widget.pathName != null
            ? 'K-Pedal: ${widget.pathName}'
            : 'K-Pedal Ride',
        text: _buildShareText(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _buildShareText() {
    final r = widget.ride;
    final name = widget.pathName ?? 'Korean cycling path';
    return 'Just finished riding $name on K-Pedal!\n'
        '${r.distanceKm.toStringAsFixed(1)} km  •  '
        '${r.formattedDuration}  •  '
        'avg ${r.avgSpeedKmh.toStringAsFixed(1)} km/h';
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              const Icon(Icons.flag_circle, color: Color(0xFF4CAF50), size: 28),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ride Complete!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (widget.pathName != null)
                    Text(
                      widget.pathName!,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats grid
          Row(
            children: [
              _StatCard(
                icon: Icons.straighten,
                value: ride.distanceKm >= 10
                    ? ride.distanceKm.toStringAsFixed(1)
                    : ride.distanceKm.toStringAsFixed(2),
                unit: 'km',
                label: 'Distance',
                color: const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 10),
              _StatCard(
                icon: Icons.timer,
                value: ride.formattedDuration,
                unit: '',
                label: 'Duration',
                color: const Color(0xFF2196F3),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatCard(
                icon: Icons.speed,
                value: ride.avgSpeedKmh.toStringAsFixed(1),
                unit: 'km/h',
                label: 'Avg Speed',
                color: const Color(0xFFFF9800),
              ),
              const SizedBox(width: 10),
              _StatCard(
                icon: Icons.rocket_launch,
                value: ride.maxSpeedKmh.toStringAsFixed(1),
                unit: 'km/h',
                label: 'Max Speed',
                color: const Color(0xFFE91E63),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Track point count
          Text(
            '${ride.points.length} GPS points recorded',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Action buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _exporting ? null : _shareGpx,
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.ios_share),
              label: Text(_exporting ? 'Preparing file...' : 'Share / Export GPX'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFC4C02), // Strava orange
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _StravaHint(),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      unit,
                      style: TextStyle(
                          color: color.withValues(alpha: 0.7), fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _StravaHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white38, size: 14),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Shares a .gpx file — open with Strava, Komoot, Garmin Connect, or any cycling app',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
