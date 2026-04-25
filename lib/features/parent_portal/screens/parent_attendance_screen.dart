import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/parent_portal_controller.dart';
import '../models/parent_portal_models.dart';
import '../widgets/loading_skeletons.dart';

class ParentAttendanceScreen extends StatefulWidget {
  const ParentAttendanceScreen({super.key, required this.childId});
  final String childId;

  @override
  State<ParentAttendanceScreen> createState() => _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState extends State<ParentAttendanceScreen> {
  ChildDetailData? _childDetail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthController>();
    final controller = context.read<ParentPortalController>();
    final cId = int.tryParse(widget.childId);
    if (cId == null || auth.currentUser == null) return;

    try {
      final detail = await controller.loadChildDetail(
        user: auth.currentUser!,
        childId: cId,
      );
      if (mounted) {
        setState(() {
          _childDetail = detail;
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
        appBar: AppBar(title: const Text('Attendance')),
        body: const DashboardLoadingSkeleton(),
      );
    }

    if (_childDetail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attendance')),
        body: const Center(child: Text('Failed to load attendance data.')),
      );
    }

    final child = _childDetail!.child;
    final timeline = _childDetail!.attendanceTimeline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(child),
            const SizedBox(height: 24),
            Text('Recent History', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildTimeline(timeline),
            const SizedBox(height: 24),
            Text('Subject Attendance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildChart(_childDetail!.classrooms),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ChildSummary child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x801A1412),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1AFFFFFF), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          Text(
            '${child.attendancePercentage ?? 0}%',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFFFF8A00)),
          ),
          const Text('Overall Attendance', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatMetric('Present', child.presentCount, Colors.green),
              _buildStatMetric('Absent', child.absentCount, Colors.red),
              _buildStatMetric('Late', child.lateCount, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric(String label, int value, Color color) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.white54)),
      ],
    );
  }

  Widget _buildTimeline(List<AttendanceChartPoint> timeline) {
    if (timeline.isEmpty) {
      return const Center(child: Text('No recent attendance records.'));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: timeline.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final point = timeline[index];
        Color statusColor = Colors.green;
        IconData statusIcon = Icons.check_circle;
        if (point.status == 'ABSENT') {
          statusColor = Colors.red;
          statusIcon = Icons.cancel;
        } else if (point.status == 'LATE') {
          statusColor = Colors.orange;
          statusIcon = Icons.schedule;
        }

        return ListTile(
          tileColor: const Color(0x331A1412),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(statusIcon, color: statusColor),
          title: Text(point.classroomName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${point.sessionDate.toLocal().toString().split(' ')[0]} - ${point.topic}'),
          trailing: Text(point.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  Widget _buildChart(List<ChildClassroomOverview> classrooms) {
    if (classrooms.isEmpty) return const SizedBox();
    
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x801A1412),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1AFFFFFF), width: 1.5),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= classrooms.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      classrooms[value.toInt()].classroomName.substring(0, 3).toUpperCase(),
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: classrooms.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.attendancePercentage ?? 0,
                  color: const Color(0xFFFF8A00),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
