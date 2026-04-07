import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

enum RecordingState { idle, recording, paused }

class TrackPoint {
  final LatLng position;
  final double? elevationM;
  final double? speedMs;
  final DateTime time;

  const TrackPoint({
    required this.position,
    this.elevationM,
    this.speedMs,
    required this.time,
  });
}

class RideRecorderProvider extends ChangeNotifier {
  RecordingState _state = RecordingState.idle;
  final List<TrackPoint> _points = [];
  DateTime? _startTime;
  DateTime? _pauseStart;
  Duration _pausedDuration = Duration.zero;
  double _distanceMeters = 0;
  double _maxSpeedMs = 0;

  RecordingState get state => _state;
  bool get isIdle => _state == RecordingState.idle;
  bool get isRecording => _state == RecordingState.recording;
  bool get isPaused => _state == RecordingState.paused;
  bool get hasData => _points.isNotEmpty;

  List<TrackPoint> get points => List.unmodifiable(_points);
  DateTime? get startTime => _startTime;

  double get distanceKm => _distanceMeters / 1000;

  Duration get elapsed {
    if (_startTime == null) return Duration.zero;
    final now = DateTime.now();
    final raw = now.difference(_startTime!);
    final paused = _state == RecordingState.paused
        ? _pausedDuration + now.difference(_pauseStart!)
        : _pausedDuration;
    return raw - paused;
  }

  double get avgSpeedKmh {
    final secs = elapsed.inSeconds;
    if (secs == 0) return 0;
    return (_distanceMeters / secs) * 3.6;
  }

  double get maxSpeedKmh => _maxSpeedMs * 3.6;

  void startRecording() {
    _state = RecordingState.recording;
    _startTime = DateTime.now();
    _pausedDuration = Duration.zero;
    _points.clear();
    _distanceMeters = 0;
    _maxSpeedMs = 0;
    notifyListeners();
  }

  void pauseRecording() {
    if (_state != RecordingState.recording) return;
    _state = RecordingState.paused;
    _pauseStart = DateTime.now();
    notifyListeners();
  }

  void resumeRecording() {
    if (_state != RecordingState.paused) return;
    if (_pauseStart != null) {
      _pausedDuration += DateTime.now().difference(_pauseStart!);
      _pauseStart = null;
    }
    _state = RecordingState.recording;
    notifyListeners();
  }

  /// Called by MapScreen on every GPS update — only stores when recording.
  void addPoint({
    required LatLng position,
    double? elevationM,
    double? speedMs,
  }) {
    if (_state != RecordingState.recording) return;

    const Distance distCalc = Distance();
    if (_points.isNotEmpty) {
      final d = distCalc.as(
        LengthUnit.Meter,
        _points.last.position,
        position,
      );
      // Ignore GPS noise (< 2m jumps)
      if (d < 2) return;
      _distanceMeters += d;
    }

    if (speedMs != null && speedMs > _maxSpeedMs) {
      _maxSpeedMs = speedMs;
    }

    _points.add(TrackPoint(
      position: position,
      elevationM: elevationM,
      speedMs: speedMs,
      time: DateTime.now(),
    ));

    notifyListeners();
  }

  /// Stops recording and returns the completed ride data.
  /// Resets state back to idle.
  CompletedRide? stopRecording() {
    if (_state == RecordingState.idle) return null;

    final ride = CompletedRide(
      points: List.from(_points),
      startTime: _startTime ?? DateTime.now(),
      elapsed: elapsed,
      distanceKm: distanceKm,
      avgSpeedKmh: avgSpeedKmh,
      maxSpeedKmh: maxSpeedKmh,
    );

    _state = RecordingState.idle;
    _points.clear();
    _startTime = null;
    _pausedDuration = Duration.zero;
    _distanceMeters = 0;
    _maxSpeedMs = 0;
    notifyListeners();

    return ride;
  }

  void discardRecording() {
    _state = RecordingState.idle;
    _points.clear();
    _startTime = null;
    _pausedDuration = Duration.zero;
    _distanceMeters = 0;
    _maxSpeedMs = 0;
    notifyListeners();
  }
}

class CompletedRide {
  final List<TrackPoint> points;
  final DateTime startTime;
  final Duration elapsed;
  final double distanceKm;
  final double avgSpeedKmh;
  final double maxSpeedKmh;

  const CompletedRide({
    required this.points,
    required this.startTime,
    required this.elapsed,
    required this.distanceKm,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
  });

  String get formattedDuration {
    final h = elapsed.inHours;
    final m = elapsed.inMinutes % 60;
    final s = elapsed.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m ${s}s';
  }
}
