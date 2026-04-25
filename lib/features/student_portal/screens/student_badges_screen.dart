import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/student_portal_controller.dart';
import '../models/student_portal_models.dart';
import '../widgets/badge_card.dart';
import '../widgets/loading_skeletons.dart';

class StudentBadgesScreen extends StatefulWidget {
  const StudentBadgesScreen({super.key});

  @override
  State<StudentBadgesScreen> createState() => _StudentBadgesScreenState();
}

class _StudentBadgesScreenState extends State<StudentBadgesScreen> {
  List<StudentBadgeItem>? _badges;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final controller = context.read<StudentPortalController>();
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) return;

    try {
      final items = await controller.loadBadges(user: user);
      if (mounted) {
        setState(() {
          _badges = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Badges & Achievements'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE52E71)))
          : _badges == null || _badges!.isEmpty
              ? const Center(child: Text('Earn badges by excelling in your classes!'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _badges!.length,
                  itemBuilder: (context, index) {
                    return BadgeCard(badge: _badges![index]);
                  },
                ),
    );
  }
}
