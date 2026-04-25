import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/student_portal_controller.dart';
import '../models/student_portal_models.dart';

class StudentTimetableScreen extends StatefulWidget {
  const StudentTimetableScreen({super.key});

  @override
  State<StudentTimetableScreen> createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends State<StudentTimetableScreen> {
  List<StudentTimetableItem>? _schedule;
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
      final items = await controller.loadTimetable(user: user);
      if (mounted) {
        setState(() {
          _schedule = items;
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
        appBar: AppBar(title: const Text('Timetable')),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFFF8A00))),
      );
    }

    if (_schedule == null || _schedule!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Timetable'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        ),
        body: const Center(child: Text('No schedule available.')),
      );
    }

    // Group by day of week
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final grouped = <int, List<StudentTimetableItem>>{};
    for (final item in _schedule!) {
      grouped.putIfAbsent(item.dayOfWeek, () => []).add(item);
    }

    return DefaultTabController(
      length: days.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Timetable'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: const Color(0xFFFF8A00),
            tabs: days.map((d) => Tab(text: d)).toList(),
          ),
        ),
        body: TabBarView(
          children: List.generate(days.length, (index) {
            final dayIndex = index + 1; // 1 = Monday
            final sessions = grouped[dayIndex] ?? [];
            if (sessions.isEmpty) {
              return const Center(child: Text('No classes scheduled for this day.', style: TextStyle(color: Colors.white54)));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final session = sessions[idx];
                final timeRange = '${session.startTime.substring(0, 5)} - ${session.endTime.substring(0, 5)}';
                
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0x331A1412),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x1AFFFFFF)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Color(0x1AFF8A00), shape: BoxShape.circle),
                      child: const Icon(Icons.schedule, color: Color(0xFFFF8A00)),
                    ),
                    title: Text(session.subject, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text('${session.roomName} • ${session.teacherName}\n$timeRange', style: const TextStyle(height: 1.5)),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
