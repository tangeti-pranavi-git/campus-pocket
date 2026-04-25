import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/parent_portal_controller.dart';
import '../models/parent_portal_models.dart';
import '../widgets/loading_skeletons.dart';

class ParentHolidayCalendarScreen extends StatefulWidget {
  const ParentHolidayCalendarScreen({super.key, required this.childId});
  final String childId;

  @override
  State<ParentHolidayCalendarScreen> createState() => _ParentHolidayCalendarScreenState();
}

class _ParentHolidayCalendarScreenState extends State<ParentHolidayCalendarScreen> {
  List<HolidayItem>? _holidays;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final controller = context.read<ParentPortalController>();
    final auth = context.read<AuthController>();
    final schoolId = auth.currentUser?.schoolId;
    if (schoolId == null) return;

    try {
      final items = await controller.loadHolidays(schoolId);
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
        appBar: AppBar(title: const Text('Holidays')),
        body: const DashboardLoadingSkeleton(),
      );
    }

    if (_holidays == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Holidays')),
        body: const Center(child: Text('Failed to load holidays.')),
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
          final isPublic = item.type == 'public';

          return ListTile(
            tileColor: const Color(0x331A1412),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPublic ? const Color(0x1AE52E71) : const Color(0x1AFF8A00),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPublic ? Icons.public : Icons.school,
                color: isPublic ? const Color(0xFFE52E71) : const Color(0xFFFF8A00),
              ),
            ),
            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item.type.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.white54)),
            trailing: Text(
              item.date.toLocal().toString().split(' ')[0],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}
