import 'package:flutter/material.dart';
import '../../../src/types/portal_user.dart';
import '../models/risk_prediction_model.dart';
import '../repositories/risk_prediction_repository.dart';

enum RiskPredictionLoadState { initial, loading, loaded, error }

class RiskPredictionController extends ChangeNotifier {
  RiskPredictionController({RiskPredictionRepository? repository})
      : _repository = repository ?? RiskPredictionRepository();

  final RiskPredictionRepository _repository;

  RiskPredictionLoadState _state = RiskPredictionLoadState.initial;
  RiskPredictionLoadState get state => _state;

  RiskPredictionModel? _riskData;
  RiskPredictionModel? get riskData => _riskData;

  String? _explanation;
  String? get explanation => _explanation;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadRiskData({required PortalUser? user, bool forceRefresh = false}) async {
    if (user == null || user.role != UserRole.student) {
      _errorMessage = 'Unauthorized or missing user data.';
      _state = RiskPredictionLoadState.error;
      notifyListeners();
      return;
    }

    if (!forceRefresh && _state == RiskPredictionLoadState.loaded && _riskData != null) {
      return;
    }

    _state = RiskPredictionLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _riskData = await _repository.getRiskPrediction(
        studentId: user.id,
        studentName: user.fullName,
        forceRefresh: forceRefresh,
      );
      _explanation = await _repository.getRiskExplanation(_riskData!);
      _state = RiskPredictionLoadState.loaded;
    } catch (e) {
      _errorMessage = 'Failed to calculate risk data: $e';
      _state = RiskPredictionLoadState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> refresh({required PortalUser? user}) => loadRiskData(user: user, forceRefresh: true);
}
