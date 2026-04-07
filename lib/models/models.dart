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

  factory CheckpointDescription.fromJson(Map<String, dynamic> json) {
    return CheckpointDescription(
      text: json['text'] as String? ?? '',
      kakaoLink: json['kakao_link'] as String?,
      naverLink: json['naver_link'] as String?,
      images: List<String>.from(json['images'] as List? ?? []),
    );
  }
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
      description: CheckpointDescription.fromJson(
        json['description'] as Map<String, dynamic>? ?? {},
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
    final desc = json['description'] as Map<String, dynamic>? ?? {};
    return TransportPoint(
      name: json['name'] as String,
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      kakaoLink: desc['kakao_link'] as String?,
      naverLink: desc['naver_link'] as String?,
    );
  }
}

class RouteSegment {
  final String name;
  final double? distanceKm;
  final List<LatLng> coordinates;

  const RouteSegment({
    required this.name,
    this.distanceKm,
    required this.coordinates,
  });

  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    final rawCoords = json['coordinates'] as List? ?? [];
    final coords = rawCoords.map((c) {
      final pair = c as List;
      return LatLng((pair[0] as num).toDouble(), (pair[1] as num).toDouble());
    }).toList();

    return RouteSegment(
      name: json['name'] as String,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      coordinates: coords,
    );
  }
}

class CyclingPath {
  final int id;
  final String name;
  final double? totalDistanceKm;
  final List<Checkpoint> checkpoints;
  final List<TransportPoint> transport;
  final List<RouteSegment> routes;

  const CyclingPath({
    required this.id,
    required this.name,
    this.totalDistanceKm,
    required this.checkpoints,
    required this.transport,
    required this.routes,
  });

  factory CyclingPath.fromJson(Map<String, dynamic> json) {
    return CyclingPath(
      id: json['id'] as int,
      name: json['name'] as String,
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble(),
      checkpoints: (json['checkpoints'] as List? ?? [])
          .map((c) => Checkpoint.fromJson(c as Map<String, dynamic>))
          .toList(),
      transport: (json['transport'] as List? ?? [])
          .map((t) => TransportPoint.fromJson(t as Map<String, dynamic>))
          .toList(),
      routes: (json['routes'] as List? ?? [])
          .map((r) => RouteSegment.fromJson(r as Map<String, dynamic>))
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
