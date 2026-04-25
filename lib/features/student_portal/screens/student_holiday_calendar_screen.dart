import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/student_portal_controller.dart';
import '../models/student_portal_models.dart';

class StudentHolidayCalendarScreen extends StatefulWidget {
  const StudentHolidayCalendarScreen({super.key});

  @override
  State<StudentHolidayCalendarScreen> createState() => _StudentHolidayCalendarScreenState();
}

class _StudentHolidayCalendarScreenState extends State<StudentHolidayCalendarScreen> {
  List<StudentHolidayItem>? _holidays;
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
      final items = await controller.loadHolidays(user: user);
      if (mounted) {
        setState(() {
          _holidays = items;
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
        appBar: AppBar(title: const Text('Holiday Calendar')),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF00B4D8))),
      );
    }

    if (_holidays == null || _holidays!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Holiday Calendar'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        ),
        body: const Center(child: Text('No holidays listed.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Holiday Calendar'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _holidays!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _holidays![index];
          
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
                decoration: const BoxDecoration(color: Color(0x1AE52E71), shape: BoxShape.circle),
                child: const Icon(Icons.event_available, color: Color(0xFFE52E71)),
              ),
              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: Text(item.type, style: const TextStyle(color: Colors.white54)),
              trailing: Text(
                DateFormat('MMM d, yyyy').format(item.date),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE52E71)),
              ),
            ),
          );
        },
      ),
    );
  }
}
