import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Persists which checkpoint IDs have been stamped.
class PassportProvider extends ChangeNotifier {
  static const _boxName = 'passport';
  late Box<bool> _box;
  bool _ready = false;

  bool get ready => _ready;

  Future<void> init() async {
    _box = await Hive.openBox<bool>(_boxName);
    _ready = true;
    notifyListeners();
  }

  bool isStamped(String checkpointId) => _box.get(checkpointId) ?? false;

  Future<void> stamp(String checkpointId) async {
    await _box.put(checkpointId, true);
    notifyListeners();
  }

  Future<void> unstamp(String checkpointId) async {
    await _box.delete(checkpointId);
    notifyListeners();
  }

  int stampedCount(List<String> ids) => ids.where(isStamped).length;

  bool pathComplete(List<String> ids) =>
      ids.isNotEmpty && ids.every(isStamped);

  Future<void> resetPath(List<String> ids) async {
    for (final id in ids) {
      await _box.delete(id);
    }
    notifyListeners();
  }
}
