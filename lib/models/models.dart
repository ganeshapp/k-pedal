import 'package:latlong2/latlong.dart';

class CheckpointDescription {
  final String text;
  final String? kakaoLink;
  final String? naverLink;
  final List<String> images;

  const CheckpointDescription({
    required this.text,
    this.kakaoLink,
    this.naverLink,
    required this.images,
  });
}

class Checkpoint {
  final String id;
  final String name;
  final LatLng position;
  final CheckpointDescription description;

  const Checkpoint({
    required this.id,
    required this.name,
    required this.position,
    required this.description,
  });

  factory Checkpoint.fromJson(Map<String, dynamic> json) {
    return Checkpoint(
      id: json['id'] as String,
      name: json['name'] as String,
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      description: CheckpointDescription(
        text: json['description'] as String? ?? '',
        kakaoLink: json['kakao_link'] as String?,
        naverLink: json['naver_link'] as String?,
        images: List<String>.from(json['images'] as List? ?? []),
      ),
    );
  }
}

class TransportPoint {
  final String name;
  final LatLng position;
  final String? kakaoLink;
  final String? naverLink;

  const TransportPoint({
    required this.name,
    required this.position,
    this.kakaoLink,
    this.naverLink,
  });

  factory TransportPoint.fromJson(Map<String, dynamic> json) {
    return TransportPoint(
      name: json['name'] as String,
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      kakaoLink: json['kakao_link'] as String?,
      naverLink: json['naver_link'] as String?,
    );
  }
}

/// Single (along_km, elevation_m) sample.
class ElevationSample {
  final double distanceKm;
  final double elevationM;

  const ElevationSample({required this.distanceKm, required this.elevationM});

  factory ElevationSample.fromJson(Map<String, dynamic> j) =>
      ElevationSample(
        distanceKm: (j['d'] as num).toDouble(),
        elevationM: (j['e'] as num).toDouble(),
      );
}

class RouteSegment {
  final String name;
  final double? distanceKm;
  final List<LatLng> coordinates;
  final List<ElevationSample> elevations;

  const RouteSegment({
    required this.name,
    this.distanceKm,
    required this.coordinates,
    required this.elevations,
  });

  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    final rawCoords = json['coordinates'] as List? ?? [];
    final coords = rawCoords.map((c) {
      final pair = c as List;
      return LatLng((pair[0] as num).toDouble(), (pair[1] as num).toDouble());
    }).toList();

    final rawElevs = json['elevations'] as List? ?? [];
    final elevs = rawElevs
        .map((e) => ElevationSample.fromJson(e as Map<String, dynamic>))
        .toList();

    return RouteSegment(
      name: json['name'] as String,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      coordinates: coords,
      elevations: elevs,
    );
  }
}

/// Pre-computed leg between two consecutive checkpoints.
class CheckpointLeg {
  final String fromId;
  final String toId;
  final double distanceKm;
  /// "along-route (segment name)" or "straight-line"
  final String method;
  final List<ElevationSample> elevations;

  const CheckpointLeg({
    required this.fromId,
    required this.toId,
    required this.distanceKm,
    required this.method,
    required this.elevations,
  });

  bool get isAlongRoute => method.startsWith('along-route');

  factory CheckpointLeg.fromJson(Map<String, dynamic> j) {
    final rawElevs = j['elevations'] as List? ?? [];
    return CheckpointLeg(
      fromId: j['from'] as String,
      toId: j['to'] as String,
      distanceKm: (j['distance_km'] as num).toDouble(),
      method: j['method'] as String? ?? '',
      elevations: rawElevs
          .map((e) => ElevationSample.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CyclingPath {
  final int id;
  final String name;
  final double? totalDistanceKm;
  final double elevationGainM;
  final double elevationLossM;
  final List<Checkpoint> checkpoints;
  final List<TransportPoint> transport;
  final List<RouteSegment> routes;
  final List<CheckpointLeg> legs;
  final List<ElevationSample> overallElevation;

  const CyclingPath({
    required this.id,
    required this.name,
    this.totalDistanceKm,
    this.elevationGainM = 0,
    this.elevationLossM = 0,
    required this.checkpoints,
    required this.transport,
    required this.routes,
    required this.legs,
    required this.overallElevation,
  });

  factory CyclingPath.fromJson(Map<String, dynamic> json) {
    return CyclingPath(
      id: json['id'] as int,
      name: json['name'] as String,
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble(),
      elevationGainM: (json['elevation_gain_m'] as num?)?.toDouble() ?? 0,
      elevationLossM: (json['elevation_loss_m'] as num?)?.toDouble() ?? 0,
      checkpoints: (json['checkpoints'] as List? ?? [])
          .map((c) => Checkpoint.fromJson(c as Map<String, dynamic>))
          .toList(),
      transport: (json['transport'] as List? ?? [])
          .map((t) => TransportPoint.fromJson(t as Map<String, dynamic>))
          .toList(),
      routes: (json['routes'] as List? ?? [])
          .map((r) => RouteSegment.fromJson(r as Map<String, dynamic>))
          .toList(),
      legs: (json['checkpoint_pairs'] as List? ?? [])
          .map((p) => CheckpointLeg.fromJson(p as Map<String, dynamic>))
          .toList(),
      overallElevation: (json['overall_elevation'] as List? ?? [])
          .map((e) => ElevationSample.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String get shortName {
    return name
        .replaceAll(' Bicycle Path', '')
        .replaceAll(' & More', '');
  }

  LatLng get center {
    if (checkpoints.isEmpty) return const LatLng(36.5, 127.5);
    double sumLat = 0, sumLng = 0;
    for (final c in checkpoints) {
      sumLat += c.position.latitude;
      sumLng += c.position.longitude;
    }
    return LatLng(sumLat / checkpoints.length, sumLng / checkpoints.length);
  }
}
