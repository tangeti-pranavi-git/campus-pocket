import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/student_portal_controller.dart';
import '../models/student_portal_models.dart';

class StudentReportCardScreen extends StatefulWidget {
  const StudentReportCardScreen({super.key});

  @override
  State<StudentReportCardScreen> createState() => _StudentReportCardScreenState();
}

class _StudentReportCardScreenState extends State<StudentReportCardScreen> {
  List<StudentAssignmentItem>? _assignments;
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
      final items = await controller.loadAssignments(user: user);
      if (mounted) {
        setState(() {
          _assignments = items;
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
        appBar: AppBar(title: const Text('Report Card')),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFE52E71))),
      );
    }

    if (_assignments == null || _assignments!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Report Card'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        ),
        body: const Center(child: Text('No academic records available.')),
      );
    }

    final graded = _assignments!.where((a) => a.score != null && a.totalScore != null).toList();
    if (graded.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Report Card'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        ),
        body: const Center(child: Text('No graded assignments yet.')),
      );
    }

    // Calculate subject averages
    final subjectScores = <String, List<double>>{};
    for (final a in graded) {
      subjectScores.putIfAbsent(a.subject, () => []).add((a.score! / a.totalScore!) * 100);
    }

    final subjectAverages = <String, double>{};
    double totalSum = 0;
    subjectScores.forEach((subject, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      subjectAverages[subject] = avg;
      totalSum += avg;
    });

    final overallAverage = totalSum / subjectAverages.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Card'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAverageCard(overallAverage),
            const SizedBox(height: 24),
            Text('Subject Performance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildChart(subjectAverages),
            const SizedBox(height: 24),
            Text('Grades Breakdown', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildSubjectsList(subjectAverages),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageCard(double averageGrade) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE52E71), Color(0xFFFF8A00)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              '${averageGrade.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text('Overall Average Grade', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(Map<String, double> subjects) {
    if (subjects.isEmpty) return const SizedBox();

    final entries = subjects.entries.toList();

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
                  if (value.toInt() >= entries.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      entries[value.toInt()].key.substring(0, 3).toUpperCase(),
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
          barGroups: entries.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: const Color(0xFF00B4D8),
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

  Widget _buildSubjectsList(Map<String, double> subjects) {
    final entries = subjects.entries.toList();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final subject = entries[index].key;
        final grade = entries[index].value;
        return ListTile(
          tileColor: const Color(0x331A1412),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text('${grade.toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF00B4D8), fontWeight: FontWeight.bold, fontSize: 16)),
        );
      },
    );
  }
}
