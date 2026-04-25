import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/parent_portal_models.dart';

class SubjectDetailScreen extends StatelessWidget {
  final String subjectName;
  final List<AssignmentScoreItem> assignments;

  const SubjectDetailScreen({
    super.key,
    required this.subjectName,
    required this.assignments,
  });

  @override
  Widget build(BuildContext context) {
    // Generate dummy data if assignments are empty to match screenshot
    final hasRealData = assignments.isNotEmpty;
    final displayData = hasRealData ? _mapRealData() : _getMockData();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F1FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.book, color: Color(0xFF2C3258), size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subjectName, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                const Text('Dr. Venkat', style: TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Text('100%', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_up, color: Colors.green, size: 16),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFF0F1FA),
                        child: const Text('V', style: TextStyle(color: Color(0xFF2C3258), fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dr. Venkat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('$subjectName Faculty', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F1FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text('${displayData.length} assessments', style: const TextStyle(color: Color(0xFF2C3258), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Score by Exam Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 24),
              _buildBarChart(displayData),
              const SizedBox(height: 32),
              _buildAssessmentList(displayData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    return SizedBox(
      height: 200,
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
                  if (value.toInt() >= data.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[value.toInt()]['shortName'],
                      style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: const TextStyle(color: Colors.black38, fontSize: 10)),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value['percentage'].toDouble(),
                  color: const Color(0xFF4ADE80), // Green color matching screenshot
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(show: true, toY: 100, color: Colors.grey.shade100),
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAssessmentList(List<Map<String, dynamic>> data) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = data[index];
        return Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(item['shortName'], style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(item['fullName'], style: const TextStyle(color: Colors.black87, fontSize: 14)),
            ),
            Text('${item['score']} / ${item['total']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _getMockData() {
    return [
      {'shortName': 'CT', 'fullName': 'DS Quiz 1', 'score': 91, 'total': 100, 'percentage': 91},
      {'shortName': 'FA', 'fullName': 'Formative Assessment 1', 'score': 87, 'total': 100, 'percentage': 87},
      {'shortName': 'CT', 'fullName': 'Class Test 1', 'score': 79, 'total': 100, 'percentage': 79},
      {'shortName': 'Proj', 'fullName': 'Project Score', 'score': 92, 'total': 100, 'percentage': 92},
      {'shortName': 'SA1', 'fullName': 'Summative Assessment 1', 'score': 85, 'total': 100, 'percentage': 85},
    ];
  }

  List<Map<String, dynamic>> _mapRealData() {
    return assignments.map((a) {
      String shortName = 'EX';
      String title = a.assignmentTitle.toLowerCase();
      if (title.contains('quiz')) shortName = 'QZ';
      if (title.contains('formative') || title.contains('fa')) shortName = 'FA';
      if (title.contains('summative') || title.contains('sa')) shortName = 'SA';
      if (title.contains('project')) shortName = 'Proj';
      if (title.contains('test') || title.contains('ct')) shortName = 'CT';

      return {
        'shortName': shortName,
        'fullName': a.assignmentTitle,
        'score': a.score.round(),
        'total': a.total.round(),
        'percentage': a.percentage,
      };
    }).toList();
  }
}
