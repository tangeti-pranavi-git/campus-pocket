import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/student_portal_controller.dart';
import '../models/student_portal_models.dart';

class StudentAnnouncementsScreen extends StatefulWidget {
  const StudentAnnouncementsScreen({super.key});

  @override
  State<StudentAnnouncementsScreen> createState() => _StudentAnnouncementsScreenState();
}

class _StudentAnnouncementsScreenState extends State<StudentAnnouncementsScreen> {
  List<StudentAnnouncementItem>? _announcements;
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
      final items = await controller.loadAnnouncements(user: user);
      if (mounted) {
        setState(() {
          _announcements = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Announcements')),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFE52E71))),
      );
    }

    if (_announcements == null || _announcements!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Announcements'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        ),
        body: const Center(child: Text('No announcements.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _announcements!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = _announcements![index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x331A1412),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE52E71).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(color: Color(0xFFE52E71), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(item.date),
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  item.content,
                  style: const TextStyle(height: 1.5, color: Colors.white70),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
