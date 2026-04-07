import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/passport_provider.dart';
import '../providers/paths_provider.dart';
import '../providers/ride_recorder_provider.dart';
import '../widgets/elevation_chart.dart';
import '../widgets/ride_summary_sheet.dart';
import 'checkpoint_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final int pathId;

  const MapScreen({super.key, required this.pathId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSub;
  LatLng? _currentPosition;
  double? _currentElevationM;
  Checkpoint? _targetCheckpoint;
  bool _followUser = true;
  bool _hasInitialLock = false;
  bool _locationPermissionDenied = false;

  // Ticks the recording timer display every second
  Timer? _uiTimer;

  CyclingPath get _path =>
      context.read<PathsProvider>().pathById(widget.pathId)!;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final recorder = context.read<RideRecorderProvider>();
      if (recorder.isRecording) setState(() {});
    });
  }

  Future<void> _initLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      if (mounted) setState(() => _locationPermissionDenied = true);
      return;
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((pos) {
      final loc = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;

      setState(() {
        _currentPosition = loc;
        _currentElevationM = pos.altitude;
      });

      if (!_hasInitialLock) {
        _hasInitialLock = true;
        _mapController.move(loc, 16);
      } else if (_followUser) {
        _mapController.move(loc, _mapController.camera.zoom);
      }

      // Feed to recorder — no-op when idle/paused
      context.read<RideRecorderProvider>().addPoint(
            position: loc,
            elevationM: pos.altitude,
            speedMs: pos.speed > 0 ? pos.speed : null,
          );

      _checkProximity(loc);
    });
  }

  void _checkProximity(LatLng loc) {
    final passport = context.read<PassportProvider>();
    const Distance distance = Distance();

    for (final checkpoint in _path.checkpoints) {
      if (passport.isStamped(checkpoint.id)) continue;
      final dist = distance.as(LengthUnit.Meter, loc, checkpoint.position);
      if (dist < 100) {
        _showProximityPrompt(checkpoint);
        break;
      }
    }
  }

  void _showProximityPrompt(Checkpoint checkpoint) {
    final passport = context.read<PassportProvider>();
    if (passport.isStamped(checkpoint.id)) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.where_to_vote, color: Color(0xFFE53935), size: 48),
            const SizedBox(height: 12),
            const Text(
              "You're at a checkpoint!",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              checkpoint.name,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  passport.stamp(checkpoint.id);
                  Navigator.pop(ctx);
                  _showStampSnack();
                },
                icon: const Icon(Icons.military_tech),
                label: const Text('Collect Stamp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStampSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.military_tech, color: Color(0xFFFFD700)),
            SizedBox(width: 8),
            Text('Stamp collected!',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: const Color(0xFF1A3A2A),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _selectTarget(Checkpoint c) {
    setState(() => _targetCheckpoint = c);
    _mapController.move(c.position, 14);
  }

  void _onRecordTap() {
    final recorder = context.read<RideRecorderProvider>();
    if (recorder.isIdle) {
      recorder.startRecording();
    } else if (recorder.isRecording) {
      recorder.pauseRecording();
    } else if (recorder.isPaused) {
      recorder.resumeRecording();
    }
  }

  Future<void> _onStopTap() async {
    final recorder = context.read<RideRecorderProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Stop Recording?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will end the ride and show your summary.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Going',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935)),
            child: const Text('Stop', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ride = recorder.stopRecording();
      if (ride != null && mounted) {
        await RideSummarySheet.show(context, ride,
            pathName: _path.name);
      }
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _uiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final path = _path;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Consumer2<PassportProvider, RideRecorderProvider>(
        builder: (context, passport, recorder, _) {
          final unstampedCheckpoints = path.checkpoints
              .where((c) => !passport.isStamped(c.id))
              .toList();

          return Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentPosition ?? path.center,
                  initialZoom: 12,
                  onPositionChanged: (_, hasGesture) {
                    if (hasGesture && _followUser) {
                      setState(() => _followUser = false);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.kpedal.app',
                  ),
                  PolylineLayer(
                    polylines: path.routes
                        .map((r) => Polyline(
                              points: r.coordinates,
                              color: const Color(0xFF4CAF50),
                              strokeWidth: 3,
                            ))
                        .toList(),
                  ),
                  if (_targetCheckpoint != null && _currentPosition != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [
                            _currentPosition!,
                            _targetCheckpoint!.position
                          ],
                          color: const Color(0xFF2196F3),
                          strokeWidth: 2,
                          pattern: StrokePattern.dotted(),
                        ),
                      ],
                    ),
                  // Recorded track
                  if (recorder.points.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: recorder.points
                              .map((p) => p.position)
                              .toList(),
                          color: const Color(0xFFFC4C02),
                          strokeWidth: 3,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: path.checkpoints.map((c) {
                      final isStamped = passport.isStamped(c.id);
                      final isTarget = _targetCheckpoint?.id == c.id;
                      return Marker(
                        point: c.position,
                        width: isTarget ? 44 : 32,
                        height: isTarget ? 44 : 32,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckpointDetailScreen(
                                checkpoint: c,
                                pathId: widget.pathId,
                              ),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isStamped
                                  ? const Color(0xFFFFD700)
                                  : (isTarget
                                      ? const Color(0xFF2196F3)
                                      : const Color(0xFFE53935)),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black38, blurRadius: 6)
                              ],
                            ),
                            child: Icon(
                              isStamped ? Icons.check : Icons.pedal_bike,
                              color: Colors.white,
                              size: isTarget ? 22 : 16,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_currentPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentPosition!,
                          width: 20,
                          height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2196F3)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Top bar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _CircleButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: !recorder.isIdle
                            ? _RecordingChip(
                                recorder: recorder,
                                elevationM: _currentElevationM,
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  path.shortName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 8),
                      _CircleButton(
                        icon: _followUser
                            ? Icons.my_location
                            : Icons.location_searching,
                        color: _followUser
                            ? const Color(0xFF2196F3)
                            : null,
                        onTap: () {
                          setState(() => _followUser = true);
                          if (_currentPosition != null) {
                            _mapController.move(_currentPosition!,
                                _mapController.camera.zoom);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Location permission warning
              if (_locationPermissionDenied)
                Positioned(
                  top: 100,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5722),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.location_off, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Location permission required for navigation',
                            style:
                                TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Recording controls (right side, above bottom panel)
              Positioned(
                right: 16,
                bottom: 120,
                child: _RecordingControls(
                  recorder: recorder,
                  onRecordTap: _onRecordTap,
                  onStopTap: _onStopTap,
                ),
              ),

              // Bottom panel
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _BottomPanel(
                  checkpoints: unstampedCheckpoints,
                  stamped: passport.stampedCount(
                      path.checkpoints.map((c) => c.id).toList()),
                  total: path.checkpoints.length,
                  targetId: _targetCheckpoint?.id,
                  onSelect: _selectTarget,
                  recorder: recorder,
                  currentElevationM: _currentElevationM,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Recording chip shown in top bar while recording/paused ──────────────────

class _RecordingChip extends StatelessWidget {
  final RideRecorderProvider recorder;
  final double? elevationM;

  const _RecordingChip({required this.recorder, this.elevationM});

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = recorder.isRecording;
    final color = isRecording ? const Color(0xFFFC4C02) : const Color(0xFFFF9800);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isRecording ? color : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _fmt(recorder.elapsed),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${recorder.distanceKm.toStringAsFixed(2)} km',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (elevationM != null) ...[
            const SizedBox(width: 8),
            const Text('▲', style: TextStyle(color: Colors.white38, fontSize: 10)),
            const SizedBox(width: 2),
            Text(
              '${elevationM!.round()}m',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Floating record / pause / stop buttons ───────────────────────────────────

class _RecordingControls extends StatelessWidget {
  final RideRecorderProvider recorder;
  final VoidCallback onRecordTap;
  final VoidCallback onStopTap;

  const _RecordingControls({
    required this.recorder,
    required this.onRecordTap,
    required this.onStopTap,
  });

  @override
  Widget build(BuildContext context) {
    if (recorder.isIdle) {
      return _RecordButton(
        onTap: onRecordTap,
        isStart: true,
        tooltip: 'Start recording',
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stop button
        _SmallCircleButton(
          icon: Icons.stop,
          color: const Color(0xFFE53935),
          tooltip: 'Stop & save ride',
          onTap: onStopTap,
        ),
        const SizedBox(height: 10),
        // Pause / Resume button
        _RecordButton(
          onTap: onRecordTap,
          isPaused: recorder.isPaused,
          tooltip: recorder.isPaused ? 'Resume recording' : 'Pause recording',
        ),
      ],
    );
  }
}

class _RecordButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isStart;
  final bool isPaused;
  final String tooltip;

  const _RecordButton({
    required this.onTap,
    this.isStart = false,
    this.isPaused = false,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    if (isStart) {
      color = const Color(0xFFE53935);
      icon = Icons.fiber_manual_record;
    } else if (isPaused) {
      color = const Color(0xFFFF9800);
      icon = Icons.play_arrow;
    } else {
      color = const Color(0xFFFC4C02);
      icon = Icons.pause;
    }

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _SmallCircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _SmallCircleButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ── Existing helpers ─────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _CircleButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Colors.black87,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? Colors.white, size: 20),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  final List<Checkpoint> checkpoints;
  final int stamped;
  final int total;
  final String? targetId;
  final void Function(Checkpoint) onSelect;
  final RideRecorderProvider recorder;
  final double? currentElevationM;

  const _BottomPanel({
    required this.checkpoints,
    required this.stamped,
    required this.total,
    required this.targetId,
    required this.onSelect,
    required this.recorder,
    this.currentElevationM,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xE6161B22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Elevation chart — only shown when recording
          if (!recorder.isIdle) ...[
            const SizedBox(height: 4),
            ElevationChart(
              points: recorder.points,
              currentElevationM: currentElevationM,
            ),
            const Divider(color: Colors.white12, height: 1),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                const Text(
                  'Next Checkpoints',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '$stamped/$total',
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (checkpoints.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.military_tech, color: Color(0xFFFFD700)),
                  SizedBox(width: 8),
                  Text(
                    'All checkpoints stamped!',
                    style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 80,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: checkpoints.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final c = checkpoints[index];
                  final isTarget = targetId == c.id;
                  return GestureDetector(
                    onTap: () => onSelect(c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isTarget
                            ? const Color(0xFF2196F3).withValues(alpha: 0.2)
                            : const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isTarget
                              ? const Color(0xFF2196F3)
                              : Colors.white12,
                          width: isTarget ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.where_to_vote,
                                color: isTarget
                                    ? const Color(0xFF2196F3)
                                    : const Color(0xFFE53935),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isTarget ? 'Target' : 'Go here',
                                style: TextStyle(
                                  color: isTarget
                                      ? const Color(0xFF2196F3)
                                      : Colors.white38,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: 140),
                            child: Text(
                              c.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
