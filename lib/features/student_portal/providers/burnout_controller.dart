import 'package:flutter/foundation.dart';
import '../models/student_analytics_models.dart';
import '../repositories/burnout_repository.dart';
import '../services/burnout_service.dart';

class BurnoutController extends ChangeNotifier {
  final BurnoutRepository _repository;
  final BurnoutService _service;

  BurnoutController({
    BurnoutRepository? repository,
    BurnoutService? service,
  })  : _repository = repository ?? BurnoutRepository(),
        _service = service ?? BurnoutService();

  BurnoutData? _data;
  bool _isLoading = false;
  String? _error;

  BurnoutData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBurnoutData(int studentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final raw = await _repository.fetchRawAnalyticsData(studentId);
      _data = _service.calculateBurnout(raw);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
