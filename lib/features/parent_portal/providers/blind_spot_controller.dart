import 'package:flutter/foundation.dart';
import '../models/parent_analytics_models.dart';
import '../repositories/parent_analytics_repository.dart';
import '../services/blind_spot_service.dart';

class BlindSpotController extends ChangeNotifier {
  final ParentAnalyticsRepository _repository;
  final BlindSpotService _service;

  BlindSpotController({
    ParentAnalyticsRepository? repository,
    BlindSpotService? service,
  })  : _repository = repository ?? ParentAnalyticsRepository(),
        _service = service ?? BlindSpotService();

  BlindSpotData? _data;
  bool _isLoading = false;
  String? _error;

  BlindSpotData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBlindSpotData(int childId, String childName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final raw = await _repository.fetchChildAnalyticsData(childId);
      _data = _service.detectBlindSpots(raw, childName);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
