import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/student_portal_controller.dart';
import '../models/student_portal_models.dart';

class StudentAttendanceScreen extends StatelessWidget {
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudentPortalController>();
    final dashboard = controller.dashboard;

    if (dashboard == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attendance')),
        body: const Center(child: Text('Data not available.')),
      );
    }

    final overall = dashboard.overallAttendancePercentage ?? 0.0;
    final classes = dashboard.classes;

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
            _buildSummaryCard(overall),
            const SizedBox(height: 24),
            Text('Subject Attendance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildChart(classes),
            const SizedBox(height: 24),
            _buildSubjectsList(classes),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double overall) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x801A1412),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1AFFFFFF), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              '${overall.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFFFF8A00)),
            ),
            const Text('Overall Attendance', style: TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<ClassFeedItem> classes) {
    if (classes.isEmpty) return const SizedBox();
    
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
                  if (value.toInt() >= classes.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      classes[value.toInt()].classroomName.substring(0, 3).toUpperCase(),
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: classes.asMap().entries.map((entry) {
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

  Widget _buildSubjectsList(List<ClassFeedItem> classes) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: classes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = classes[index];
        final pct = item.attendancePercentage ?? 0.0;
        
        return ListTile(
          tileColor: const Color(0x331A1412),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(item.classroomName, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text('${pct.toStringAsFixed(1)}%', style: TextStyle(color: pct < 75 ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
        );
      },
    );
  }
}
