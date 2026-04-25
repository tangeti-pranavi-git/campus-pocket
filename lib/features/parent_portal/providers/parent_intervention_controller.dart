import 'package:flutter/foundation.dart';
import '../models/parent_analytics_models.dart';
import '../repositories/parent_analytics_repository.dart';
import '../services/parent_intervention_service.dart';

class ParentInterventionController extends ChangeNotifier {
  final ParentAnalyticsRepository _repository;
  final ParentInterventionService _service;

  ParentInterventionController({
    ParentAnalyticsRepository? repository,
    ParentInterventionService? service,
  })  : _repository = repository ?? ParentAnalyticsRepository(),
        _service = service ?? ParentInterventionService();

  InterventionCoachData? _data;
  bool _isLoading = false;
  String? _error;

  InterventionCoachData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadInterventionData(int childId, String childName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final raw = await _repository.fetchChildAnalyticsData(childId);
      _data = _service.generateIntervention(raw, childName);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
