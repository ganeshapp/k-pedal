import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/models.dart';

class PathRepository {
  static List<CyclingPath>? _cache;

  static Future<List<CyclingPath>> loadPaths() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/paths.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final list = (json['paths'] as List)
        .map((p) => CyclingPath.fromJson(p as Map<String, dynamic>))
        .toList();
    _cache = list;
    return list;
  }
}
