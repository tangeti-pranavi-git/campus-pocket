import 'package:flutter/foundation.dart';
import '../models/student_analytics_models.dart';
import '../repositories/exam_readiness_repository.dart';
import '../services/exam_readiness_service.dart';

class ExamReadinessController extends ChangeNotifier {
  final ExamReadinessRepository _repository;
  final ExamReadinessService _service;

  ExamReadinessController({
    ExamReadinessRepository? repository,
    ExamReadinessService? service,
  })  : _repository = repository ?? ExamReadinessRepository(),
        _service = service ?? ExamReadinessService();

  ExamReadinessData? _data;
  bool _isLoading = false;
  String? _error;

  ExamReadinessData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadReadinessData(int studentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final raw = await _repository.fetchRawReadinessData(studentId);
      _data = _service.calculateReadiness(raw);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
