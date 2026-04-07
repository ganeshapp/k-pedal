import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';

// Top-level so compute() can serialize it to a background isolate
List<CyclingPath> _parsePaths(String raw) {
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return (json['paths'] as List)
      .map((p) => CyclingPath.fromJson(p as Map<String, dynamic>))
      .toList();
}

class PathRepository {
  static List<CyclingPath>? _cache;

  static Future<List<CyclingPath>> loadPaths() async {
    if (_cache != null) return _cache!;
    // Load string on main isolate (required for rootBundle),
    // then parse JSON off the main thread to avoid blocking UI.
    final raw = await rootBundle.loadString('assets/data/paths.json');
    final list = await compute(_parsePaths, raw);
    _cache = list;
    return list;
  }
}
