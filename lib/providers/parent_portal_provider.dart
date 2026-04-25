import 'package:provider/provider.dart';

import '../features/parent_portal/controllers/parent_portal_controller.dart';
import '../repositories/parent_portal_repository.dart';
import '../src/contexts/auth_controller.dart';

ChangeNotifierProxyProvider<AuthController, ParentPortalController>
    buildParentPortalProvider() {
  return ChangeNotifierProxyProvider<AuthController, ParentPortalController>(
    create: (_) => ParentPortalController(ParentPortalRepository()),
    update: (_, auth, controller) {
      final target = controller ?? ParentPortalController(ParentPortalRepository());
      if (auth.isParent) {
        target.loadDashboard(user: auth.currentUser);
      }
      return target;
    },
  );
}
