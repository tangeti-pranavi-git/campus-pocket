import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/student_portal/providers/student_portal_provider.dart';
import '../features/student_portal/providers/risk_prediction_provider.dart';
import '../providers/parent_portal_provider.dart';
import 'app_router.dart';
import 'contexts/auth_controller.dart';
import 'repositories/auth_repository.dart';
import '../features/ai_chat/providers/ai_chat_provider.dart';
import '../features/ai_chat/services/ai_chat_service.dart';
import '../features/student_portal/providers/burnout_controller.dart';
import '../features/student_portal/providers/exam_readiness_controller.dart';
import '../features/parent_portal/providers/parent_intervention_controller.dart';
import '../features/parent_portal/providers/blind_spot_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/notification_controller.dart';

class CampusPocketApp extends StatefulWidget {
  const CampusPocketApp({super.key});

  @override
  State<CampusPocketApp> createState() => _CampusPocketAppState();
}

class _CampusPocketAppState extends State<CampusPocketApp> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(AuthRepository());
    _authController.initialize();
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: _authController),
        buildParentPortalProvider(),
        buildStudentPortalProvider(),
        buildRiskPredictionProvider(),
        ChangeNotifierProvider<AiChatProvider>(
          create: (_) => AiChatProvider(AiChatService(Supabase.instance.client)),
        ),
        ChangeNotifierProvider<BurnoutController>(
          create: (_) => BurnoutController(),
        ),
        ChangeNotifierProvider<ExamReadinessController>(
          create: (_) => ExamReadinessController(),
        ),
        ChangeNotifierProvider<ParentInterventionController>(
          create: (_) => ParentInterventionController(),
        ),
        ChangeNotifierProvider<BlindSpotController>(
          create: (_) => BlindSpotController(),
        ),
        ChangeNotifierProvider<NotificationController>(
          create: (_) => NotificationController(Supabase.instance.client)..initialize(),
        ),
      ],
      child: Consumer<AuthController>(
        builder: (context, auth, _) {
          final router = buildRouter(auth);

          return MaterialApp.router(
            title: 'Campus Pocket',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.dark, // Force dark mode for the premium look
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF0F0B0A), // Deep premium warm dark background
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFFF8A00), // Vibrant Orange
                secondary: Color(0xFFE52E71), // Deep Pink/Red
                surface: Color(0xFF1A1412), // Slightly lighter for cards
                background: Color(0xFF0F0B0A),
                error: Color(0xFFFF3366),
                onPrimary: Colors.black,
                onSurface: Colors.white,
              ),
              useMaterial3: true,
              fontFamily: 'Roboto', // Safe fallback, can use custom fonts if added
              textTheme: const TextTheme(
                headlineLarge: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -1),
                headlineMedium: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
                titleLarge: TextStyle(fontWeight: FontWeight.w600),
                bodyLarge: TextStyle(color: Color(0xFFE2E8F0)),
                bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF261D1A), // Warm dark for inputs
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFFF8A00), width: 1.5), // Orange focus
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFFF3366), width: 1.5),
                ),
                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A00), // Orange button
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              cardTheme: CardThemeData(
                color: const Color(0xFF1A1412),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0x1AFFFFFF), width: 1),
                ),
              ),
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
