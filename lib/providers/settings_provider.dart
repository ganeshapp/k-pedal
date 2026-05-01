import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum MapProvider { kakao, naver }

/// Persists user preferences (currently just the preferred map provider
/// for "Open in Maps" and "Find Nearby" actions).
class SettingsProvider extends ChangeNotifier {
  static const _boxName = 'settings';
  static const _mapProviderKey = 'map_provider';

  late Box _box;

  MapProvider _mapProvider = MapProvider.kakao;
  MapProvider get mapProvider => _mapProvider;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    final stored = _box.get(_mapProviderKey) as String?;
    if (stored == 'naver') _mapProvider = MapProvider.naver;
  }

  Future<void> setMapProvider(MapProvider value) async {
    if (_mapProvider == value) return;
    _mapProvider = value;
    await _box.put(_mapProviderKey, value == MapProvider.naver ? 'naver' : 'kakao');
    notifyListeners();
  }
}
