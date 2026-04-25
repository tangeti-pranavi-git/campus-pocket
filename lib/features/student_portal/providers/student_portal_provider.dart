import 'package:provider/provider.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/student_portal_controller.dart';
import '../repositories/student_portal_repository.dart';

ChangeNotifierProxyProvider<AuthController, StudentPortalController>
    buildStudentPortalProvider() {
  return ChangeNotifierProxyProvider<AuthController, StudentPortalController>(
    create: (_) => StudentPortalController(StudentPortalRepository()),
    update: (_, auth, controller) {
      final target = controller ?? StudentPortalController(StudentPortalRepository());
      if (auth.isStudent) {
        target.ensureInitialized(auth.currentUser);
      }
      return target;
    },
  );
}
