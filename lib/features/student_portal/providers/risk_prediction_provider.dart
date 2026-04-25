import 'package:provider/provider.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/risk_prediction_controller.dart';
import '../repositories/risk_prediction_repository.dart';

ChangeNotifierProxyProvider<AuthController, RiskPredictionController>
    buildRiskPredictionProvider() {
  return ChangeNotifierProxyProvider<AuthController, RiskPredictionController>(
    create: (_) => RiskPredictionController(repository: RiskPredictionRepository()),
    update: (_, auth, controller) {
      final target = controller ?? RiskPredictionController(repository: RiskPredictionRepository());
      if (auth.isStudent) {
        // Load data in background when auth updates
        target.loadRiskData(user: auth.currentUser);
      }
      return target;
    },
  );
}
