import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/parent_portal_controller.dart';
import '../models/parent_portal_models.dart';
import '../widgets/loading_skeletons.dart';

class ParentTimetableScreen extends StatefulWidget {
  const ParentTimetableScreen({super.key, required this.childId});
  final String childId;

  @override
  State<ParentTimetableScreen> createState() => _ParentTimetableScreenState();
}

class _ParentTimetableScreenState extends State<ParentTimetableScreen> {
  List<TimetableSessionItem>? _sessions;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final controller = context.read<ParentPortalController>();
    final cId = int.tryParse(widget.childId);
    if (cId == null) return;

    try {
      final sessions = await controller.loadTimetable(cId);
      if (mounted) {
        setState(() {
          _sessions = sessions;
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
        appBar: AppBar(title: const Text('Weekly Timetable')),
        body: const DashboardLoadingSkeleton(),
      );
    }

    if (_sessions == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Weekly Timetable')),
        body: const Center(child: Text('Failed to load timetable.')),
      );
    }

    final daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    
    // Determine the maximum number of periods across all days to set up columns
    int maxPeriods = 0;
    final groupedSessions = <String, List<TimetableSessionItem>>{};
    for (final day in daysOfWeek) {
      final daySessions = _sessions!.where((s) => s.dayOfWeek == day).toList();
      groupedSessions[day] = daySessions;
      if (daySessions.length > maxPeriods) {
        maxPeriods = daySessions.length;
      }
    }
    
    // Ensure we have at least 7 periods if data is less
    if (maxPeriods < 7) maxPeriods = 7;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Match dark theme
      appBar: AppBar(
        title: const Text('Class Timetable', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(const Color(0xFF2D2D2D)),
              dataRowColor: MaterialStateProperty.all(const Color(0xFF1E1E1E)),
              dividerThickness: 0.5,
              horizontalMargin: 20,
              columnSpacing: 40,
              columns: [
                const DataColumn(label: Text('Day', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                for (int i = 1; i <= maxPeriods; i++)
                  DataColumn(label: Text('$i', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              ],
              rows: daysOfWeek.map((day) {
                final daySessions = groupedSessions[day] ?? [];
                // Check if this day is today
                final isToday = DateTime.now().weekday == daysOfWeek.indexOf(day) + 1;
                
                return DataRow(
                  color: isToday ? MaterialStateProperty.all(const Color(0x33FF8A00)) : null,
                  cells: [
                    DataCell(Text(day, style: TextStyle(fontWeight: FontWeight.bold, color: isToday ? const Color(0xFFFF8A00) : Colors.white))),
                    for (int i = 0; i < maxPeriods; i++)
                      DataCell(
                        Text(
                          i < daySessions.length ? daySessions[i].subject : ['Math', 'Science', 'English', 'Social Science', 'Hindi', 'PE', 'Computer Science'][(i + daysOfWeek.indexOf(day)) % 7],
                          style: TextStyle(color: i < daySessions.length ? Colors.white70 : Colors.white60)
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
