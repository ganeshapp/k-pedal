import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../providers/ride_recorder_provider.dart';

class GpxService {
  /// Generates a GPX string from a completed ride.
  static String buildGpx(CompletedRide ride, {String? pathName}) {
    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buf.writeln(
        '<gpx version="1.1" creator="K-Pedal" '
        'xmlns="http://www.topografix.com/GPX/1/1" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:schemaLocation="http://www.topografix.com/GPX/1/1 '
        'http://www.topografix.com/GPX/1/1/gpx.xsd">');

    final name = pathName ?? 'K-Pedal Ride';
    final desc = '${ride.distanceKm.toStringAsFixed(2)} km — '
        '${ride.formattedDuration} — '
        'avg ${ride.avgSpeedKmh.toStringAsFixed(1)} km/h';

    buf.writeln('  <metadata>');
    buf.writeln('    <name>${_escape(name)}</name>');
    buf.writeln('    <desc>${_escape(desc)}</desc>');
    buf.writeln('    <time>${ride.startTime.toUtc().toIso8601String()}</time>');
    buf.writeln('  </metadata>');

    buf.writeln('  <trk>');
    buf.writeln('    <name>${_escape(name)}</name>');
    buf.writeln('    <type>cycling</type>');
    buf.writeln('    <trkseg>');

    for (final pt in ride.points) {
      final lat = pt.position.latitude.toStringAsFixed(7);
      final lng = pt.position.longitude.toStringAsFixed(7);
      buf.write('      <trkpt lat="$lat" lon="$lng">');
      if (pt.elevationM != null) {
        buf.write('<ele>${pt.elevationM!.toStringAsFixed(1)}</ele>');
      }
      buf.write('<time>${pt.time.toUtc().toIso8601String()}</time>');
      buf.writeln('</trkpt>');
    }

    buf.writeln('    </trkseg>');
    buf.writeln('  </trk>');
    buf.writeln('</gpx>');

    return buf.toString();
  }

  /// Saves GPX to a temporary file and returns the path.
  static Future<File> saveGpx(CompletedRide ride, {String? pathName}) async {
    final gpx = buildGpx(ride, pathName: pathName);
    final dir = await getTemporaryDirectory();
    final timestamp = ride.startTime
        .toLocal()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-')
        .substring(0, 19);
    final file = File('${dir.path}/kpedal_$timestamp.gpx');
    await file.writeAsString(gpx, flush: true);
    return file;
  }

  static String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
