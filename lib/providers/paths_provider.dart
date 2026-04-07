import 'package:flutter/foundation.dart';
import '../data/path_repository.dart';
import '../models/models.dart';

class PathsProvider extends ChangeNotifier {
  List<CyclingPath> _paths = [];
  bool _loading = true;

  List<CyclingPath> get paths => _paths;
  bool get loading => _loading;

  CyclingPath? pathById(int id) {
    try {
      return _paths.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    _paths = await PathRepository.loadPaths();
    _loading = false;
    notifyListeners();
  }
}
