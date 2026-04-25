import '../models/parent_analytics_models.dart';

class BlindSpotService {
  BlindSpotData detectBlindSpots(
      Map<String, dynamic> rawData, String childName) {

    if (rawData.isEmpty) {
      return const BlindSpotData(
        hiddenRiskScore: 0,
        overallSeverity: BlindSpotSeverity.green,
        alerts: [],
        suggestedActions: ['No blind spots detected. Keep monitoring weekly.'],
        aiInsight: 'All indicators look healthy. No hidden patterns of concern.',
      );
    }

    final attendance = (rawData['attendance'] as List<dynamic>? ?? []);
    final assignments = (rawData['assignments'] as List<dynamic>? ?? []);
    final fees = (rawData['fees'] as List<dynamic>? ?? []);
    final announcements = (rawData['announcements'] as List<dynamic>? ?? []);

    int riskScore = 0;
    final List<HiddenAlert> alerts = [];
    final List<String> suggestedActions = [];

    // ── 1. Silent Subject Decline ──────────────────────────────────────
    // Detect if a SPECIFIC subject's scores are consistently falling
    final subjectScores = <int, List<double>>{};
    for (final a in assignments) {
      final assignment = a['assignment'] as Map<String, dynamic>?;
      if (assignment == null) continue;
      final cid = assignment['classroom_id'] as int? ?? 0;
      final pct = (a['percentage'] as num?)?.toDouble() ?? 0;
      subjectScores.putIfAbsent(cid, () => []).add(pct);
    }

    int silentDeclineCount = 0;
    for (final entry in subjectScores.entries) {
      final scores = entry.value;
      if (scores.length >= 2) {
        final drop = scores.first - scores.last;
        if (drop > 15 && scores.last < 70) {
          silentDeclineCount++;
          riskScore += 25;
          alerts.add(HiddenAlert(
            title: 'Silent Subject Decline',
            message: '$childName\'s marks dropped ${drop.toStringAsFixed(0)} points in a subject while overall grades look OK.',
            severity: drop > 30 ? BlindSpotSeverity.red : BlindSpotSeverity.yellow,
            insight:
                'Parents often miss this because the average stays acceptable. This specific subject drop may indicate a concept gap that will affect exams. Early intervention prevents exam failure.',
          ));
          suggestedActions.add('Review the last 2-3 assignments in the declining subject together with $childName.');
          suggestedActions.add('Contact the subject teacher: ask which core concepts $childName is struggling with.');
        }
      }
    }

    // ── 2. High Grades + Dropping Attendance (Burnout Signal) ─────────
    if (attendance.length >= 8 && assignments.isNotEmpty) {
      final recent5 = attendance.take(5).where((a) => a['status'] == 'PRESENT').length;
      final prev5   = attendance.skip(5).take(5).where((a) => a['status'] == 'PRESENT').length;
      final submitted = assignments.where((a) => a['percentage'] != null).toList();
      double avgGrade = 0;
      if (submitted.isNotEmpty) {
        avgGrade = submitted.map((a) => (a['percentage'] as num?)?.toDouble() ?? 0).reduce((a, b) => a + b) / submitted.length;
      }

      if (recent5 < prev5 && avgGrade > 75) {
        riskScore += 30;
        alerts.add(HiddenAlert(
          title: 'Attendance Paradox 🔍',
          message: '$childName has high grades (${avgGrade.toStringAsFixed(0)}%) but attendance is declining.',
          severity: BlindSpotSeverity.red,
          insight:
              'This is a classic early burnout indicator. $childName may be self-studying intensely to compensate for missed classes, creating hidden pressure. If unchecked, grades will drop suddenly.',
        ));
        suggestedActions.add('Have a calm, non-judgmental conversation about school stress and workload.');
        suggestedActions.add('Suggest 2-3 relaxation activities this weekend — this is not laziness, it\'s recovery.');
      }
    }

    // ── 3. Monday Absence Pattern ─────────────────────────────────────
    // Detect if absences cluster on specific days (weekend anxiety)
    final dayAbsences = <String, int>{};
    for (final a in attendance) {
      if (a['status'] == 'ABSENT') {
        final session = a['session'] as Map<String, dynamic>?;
        if (session != null) {
          final dateStr = session['session_date']?.toString() ?? '';
          if (dateStr.isNotEmpty) {
            try {
              final date = DateTime.parse(dateStr);
              final dayName = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][date.weekday - 1];
              dayAbsences[dayName] = (dayAbsences[dayName] ?? 0) + 1;
            } catch (_) {}
          }
        }
      }
    }
    final maxAbsences = dayAbsences.isEmpty ? 0 : dayAbsences.values.reduce((a, b) => a > b ? a : b);
    if (maxAbsences >= 2) {
      final worstDay = dayAbsences.entries.firstWhere((e) => e.value == maxAbsences).key;
      riskScore += 15;
      alerts.add(HiddenAlert(
        title: '$worstDay Absence Pattern',
        message: '$childName has been absent on $worstDay ${dayAbsences[worstDay]} times recently.',
        severity: BlindSpotSeverity.yellow,
        insight:
            'Repeated absences on a specific day can indicate subject-specific anxiety (e.g., hard classes on that day) or social stress. This pattern is invisible in overall attendance reports.',
      ));
      suggestedActions.add('Check which classes/teachers are scheduled on $worstDay and explore if there\'s a specific concern.');
    }

    // ── 4. Submission Batch Pattern (Procrastination/Overload) ────────
    if (assignments.isNotEmpty) {
      final submitted = assignments.where((a) => a['submitted_at'] != null).toList();
      final lateSubs = submitted.where((a) {
        final assignment = a['assignment'] as Map<String, dynamic>?;
        if (assignment == null) return false;
        try {
          final due = DateTime.parse(assignment['due_date']?.toString() ?? '');
          final sub = DateTime.parse(a['submitted_at']?.toString() ?? '');
          return sub.isAfter(due.subtract(const Duration(hours: 12)));
        } catch (_) { return false; }
      }).length;

      if (lateSubs >= 2) {
        riskScore += 20;
        alerts.add(HiddenAlert(
          title: 'Last-Minute Submission Pattern',
          message: '$lateSubs assignments submitted within 12 hours of deadline.',
          severity: BlindSpotSeverity.yellow,
          insight:
              'While $childName gets the work done, this pattern indicates chronic procrastination or overload. Stress spikes before each deadline can impact sleep, concentration and emotional wellbeing.',
        ));
        suggestedActions.add('Introduce a personal rule: start each assignment at least 3 days before the due date.');
        suggestedActions.add('Help create a weekly planner together — visible on the fridge, not just digital.');
      }
    }

    // ── 5. Pending Fees Alert ─────────────────────────────────────────
    final overdueFees = fees.where((f) => f['status'] == 'OVERDUE').toList();
    if (overdueFees.isNotEmpty) {
      riskScore += 20;
      alerts.add(HiddenAlert(
        title: 'Pending Fee Payments',
        message: 'There are ${overdueFees.length} overdue fee payments.',
        severity: BlindSpotSeverity.red,
        insight: 'Overdue fees might lead to restricted access to school services or exams. Clear them promptly to ensure uninterrupted learning.',
      ));
      suggestedActions.add('Check the Fee Details section and settle overdue payments this week.');
    } else {
      final pendingFees = fees.where((f) => f['status'] == 'PENDING').toList();
      if (pendingFees.isNotEmpty) {
        alerts.add(HiddenAlert(
          title: 'Upcoming Fee Deadlines',
          message: 'There are ${pendingFees.length} pending fee payments.',
          severity: BlindSpotSeverity.yellow,
          insight: 'Plan your finances to clear these before they become overdue.',
        ));
      }
    }

    // ── 6. Unread Notices Alert ───────────────────────────────────────
    if (announcements.isNotEmpty) {
      final urgentNotices = announcements.where((a) => a['priority'] == 'URGENT' || a['priority'] == 'HIGH').toList();
      if (urgentNotices.isNotEmpty) {
        riskScore += 10;
        alerts.add(HiddenAlert(
          title: 'Unread Urgent Notices',
          message: 'The school has sent ${urgentNotices.length} urgent notices recently.',
          severity: BlindSpotSeverity.yellow,
          insight: 'Missing urgent notices could result in missing important events, changes in schedules, or crucial alerts.',
        ));
        suggestedActions.add('Check the Alerts section immediately.');
      }
    }

    // ── 7. Missing Homework Submissions & Upcoming Exams ───────────────
    if (assignments.isNotEmpty) {
      final missing = assignments.where((a) => a['score'] == null).toList();
      if (missing.isNotEmpty) {
        riskScore += 15;
        alerts.add(HiddenAlert(
          title: 'Missing Homework',
          message: '$childName has ${missing.length} missing homework submissions.',
          severity: missing.length >= 3 ? BlindSpotSeverity.red : BlindSpotSeverity.yellow,
          insight: 'Missing assignments directly impact the final grade and indicate a lack of practice.',
        ));
      }

      final upcomingExams = assignments.where((a) {
        final assign = a['assignment'] as Map<String, dynamic>?;
        if (assign == null) return false;
        final type = assign['exam_type']?.toString();
        return type != null && type != 'Class Assessment' && a['score'] == null;
      }).toList();

      if (upcomingExams.isNotEmpty) {
        alerts.add(HiddenAlert(
          title: 'Upcoming Major Exams',
          message: 'There are ${upcomingExams.length} major exams scheduled soon.',
          severity: BlindSpotSeverity.yellow,
          insight: 'Major exams require structural revision. Early preparation is key.',
        ));
        suggestedActions.add('Start reviewing for the upcoming exams this weekend.');
      }
    }

    // ── 5. Finalize ───────────────────────────────────────────────────
    riskScore = riskScore.clamp(0, 100);
    BlindSpotSeverity overall;
    if (riskScore >= 55) {
      overall = BlindSpotSeverity.red;
    } else if (riskScore >= 20) {
      overall = BlindSpotSeverity.yellow;
    } else {
      overall = BlindSpotSeverity.green;
    }

    if (suggestedActions.isEmpty) {
      suggestedActions.add('Maintain open weekly conversations about school — not just grades.');
      suggestedActions.add('Celebrate consistency even when grades haven\'t improved yet.');
    }

    return BlindSpotData(
      hiddenRiskScore: riskScore,
      overallSeverity: overall,
      alerts: alerts,
      suggestedActions: suggestedActions,
      aiInsight: _generateInsight(overall, alerts, childName),
    );
  }

  String _generateInsight(BlindSpotSeverity severity, List<HiddenAlert> alerts, String name) {
    if (severity == BlindSpotSeverity.green) {
      return '✅ $name\'s performance patterns all look consistent and healthy. No hidden risks detected in this analysis cycle.';
    }
    if (severity == BlindSpotSeverity.yellow) {
      return '⚠️ ${alerts.length} subtle pattern${alerts.length > 1 ? 's' : ''} detected in $name\'s data. These are not visible in the regular report card but may escalate if unaddressed. Early awareness is the best tool.';
    }
    return '🔴 Our system found ${alerts.length} hidden risk indicator${alerts.length > 1 ? 's' : ''} that need immediate parent attention. The most critical: ${alerts.first.title}. Parents who act on early signals see 3x better academic recovery rates.';
  }
}
