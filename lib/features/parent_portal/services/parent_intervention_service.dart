import 'package:flutter/material.dart';
import '../models/parent_analytics_models.dart';

class ParentInterventionService {
  InterventionCoachData generateIntervention(
      Map<String, dynamic> rawData, String childName) {

    if (rawData.isEmpty) {
      return _stableResult(childName);
    }

    final attendance = (rawData['attendance'] as List<dynamic>? ?? []);
    final assignments = (rawData['assignments'] as List<dynamic>? ?? []);

    int supportScore = 100;
    final List<ActionPlanItem> actionPlan = [];
    final List<String> academicActions = [];
    final List<String> emotionalTips = [];
    final List<String> teacherFollowups = [];
    final List<String> upcomingDeadlines = [];

    // ── 1. Attendance Analysis ──────────────────────────────────────────
    double attPct = 100;
    if (attendance.isNotEmpty) {
      final presentCount = attendance.where((a) => a['status'] == 'PRESENT').length;
      final lateCount = attendance.where((a) => a['status'] == 'LATE').length;
      attPct = ((presentCount + lateCount * 0.5) / attendance.length) * 100;

      if (attPct < 60) {
        supportScore -= 30;
        actionPlan.add(ActionPlanItem(
          title: 'Critical Attendance Alert',
          description: '$childName has only ${attPct.toStringAsFixed(0)}% attendance — risk of academic penalty.',
          icon: Icons.warning_amber_rounded,
        ));
        academicActions.add('Arrange a parent-teacher meeting this week about attendance.');
        academicActions.add('Identify if there are transport, health or motivation barriers.');
        teacherFollowups.add('Request class notes for all missed sessions from the class teacher.');
      } else if (attPct < 75) {
        supportScore -= 18;
        actionPlan.add(ActionPlanItem(
          title: 'Attendance Warning',
          description: 'Attendance is ${attPct.toStringAsFixed(0)}%. Target minimum 85% to avoid penalties.',
          icon: Icons.access_time_rounded,
        ));
        academicActions.add('Discuss morning routines — set alarm 30 mins earlier if needed.');
        teacherFollowups.add('Ask class teacher for a summary of missed key topics.');
      } else if (attPct < 85) {
        supportScore -= 8;
        academicActions.add('Maintain current attendance — aim to exceed 85% consistently.');
      }
    }

    // ── 2. Assignment Performance Analysis ─────────────────────────────
    final submitted = assignments.where((a) => a['percentage'] != null).toList();
    final pending = assignments.where((a) => a['percentage'] == null).toList();

    if (pending.length >= 3) {
      supportScore -= 15;
      actionPlan.add(ActionPlanItem(
        title: 'Workload Overload Risk',
        description: '$childName has ${pending.length} pending assignments. Prioritize immediately.',
        icon: Icons.assignment_late_outlined,
      ));
      academicActions.add('Help $childName list all pending tasks and set completion dates.');
      academicActions.add('Tackle the oldest overdue assignment first — even 30 mins per day helps.');
      upcomingDeadlines.add('${pending.length} assignments pending — review today');
    } else if (pending.isNotEmpty) {
      upcomingDeadlines.add('${pending.length} assignment${pending.length > 1 ? 's' : ''} upcoming');
    }

    // ── 3. Grade Trend Analysis ─────────────────────────────────────────
    if (submitted.isNotEmpty) {
      final percentages = submitted
          .map((a) => (a['percentage'] as num?)?.toDouble() ?? 0)
          .toList();
      final avgGrade = percentages.reduce((a, b) => a + b) / percentages.length;
      final lowGradeCount = percentages.where((p) => p < 60).length;

      // Subject-specific weakness detection
      final subjectMap = <int, List<double>>{};
      for (final a in submitted) {
        final assignment = a['assignment'] as Map<String, dynamic>?;
        if (assignment == null) continue;
        final cid = assignment['classroom_id'] as int? ?? 0;
        final pct = (a['percentage'] as num?)?.toDouble() ?? 0;
        subjectMap.putIfAbsent(cid, () => []).add(pct);
      }

      // Detect silent declining subjects and weak subjects
      String weakSubjectStr = '';
      for (final entry in subjectMap.entries) {
        final grades = entry.value;
        if (grades.isNotEmpty) {
          final avg = grades.reduce((a, b) => a + b) / grades.length;
          if (avg < 50) {
             final subjName = (assignments.firstWhere((a) => (a['assignment']?['classroom_id'] ?? 0) == entry.key, orElse: () => {})['assignment']?['classroom']?['name'] ?? 'Subject').toString();
             weakSubjectStr = subjName;
             supportScore -= 10;
             actionPlan.add(ActionPlanItem(
               title: 'Weak Subject Alert: $subjName',
               description: 'Marks are low in $subjName. Recommend dedicated practice sessions immediately.',
               icon: Icons.menu_book_rounded,
             ));
             academicActions.add('Schedule 3 extra practice sessions for $subjName this week.');
          }
        }
        if (grades.length >= 2) {
          final recent = grades.last;
          final earlier = grades.first;
          if (earlier - recent > 20 && recent < 65) {
            supportScore -= 10;
            actionPlan.add(ActionPlanItem(
              title: 'Subject Decline Detected',
              description: 'Performance dropped ${(earlier - recent).toStringAsFixed(0)} points — needs targeted help.',
              icon: Icons.trending_down_rounded,
            ));
            teacherFollowups.add('Contact the subject teacher — ask for specific weak areas and revision material.');
          }
        }
      }

      if (avgGrade < 50) {
        supportScore -= 15;
        actionPlan.add(ActionPlanItem(
          title: 'Academic Recovery Plan',
          description: 'Average grade is ${avgGrade.toStringAsFixed(0)}%. Structured revision is essential.',
          icon: Icons.auto_graph_rounded,
        ));
        academicActions.add('Set aside 45 mins of focused study daily — no distractions.');
        academicActions.add('Review all returned assignments together and rework wrong answers.');
        teacherFollowups.add('Ask each subject teacher: "What are the 3 most important topics for the next exam?"');
      } else if (avgGrade < 70 && lowGradeCount > 0) {
        supportScore -= 8;
        academicActions.add('Focus revision on the ${lowGradeCount} subject${lowGradeCount > 1 ? 's' : ''} scoring below 60%.');
        teacherFollowups.add('Request sample papers or revision questions from weak subject teachers.');
      } else if (avgGrade >= 80) {
        actionPlan.add(ActionPlanItem(
          title: 'Sustain Excellence',
          description: '$childName is performing well (${avgGrade.toStringAsFixed(0)}%). Keep the momentum going.',
          icon: Icons.star_rounded,
        ));
      }
    }

    // ── 4. Universal Emotional Tips ─────────────────────────────────────
    emotionalTips.add('Acknowledge one specific thing $childName did well this week — be precise, not generic.');
    emotionalTips.add('Limit screen time 1 hour before bedtime. Sleep quality directly affects memory and grades.');
    emotionalTips.add('Ask open questions: "What was the most interesting thing you studied today?" — not just "How was school?"');
    if (attPct < 80) {
      emotionalTips.add('Check if $childName is feeling anxious or overwhelmed — sometimes poor attendance signals emotional stress.');
    }

    // ── 5. Finalize ──────────────────────────────────────────────────────
    supportScore = supportScore.clamp(0, 100);
    SupportPriority priority;
    if (supportScore < 50) {
      priority = SupportPriority.high;
    } else if (supportScore < 75) {
      priority = SupportPriority.medium;
    } else {
      priority = SupportPriority.low;
    }

    if (actionPlan.isEmpty) {
      actionPlan.add(const ActionPlanItem(
        title: 'Stay Consistent',
        description: 'Your child is performing well. Celebrate the wins and keep the routine.',
        icon: Icons.check_circle_outline,
      ));
    }

    if (academicActions.isEmpty) {
      academicActions.add('Continue daily 30-minute revision even on non-exam weeks.');
    }
    if (teacherFollowups.isEmpty) {
      teacherFollowups.add('Schedule a brief monthly check-in with the class teacher to stay informed.');
    }

    return InterventionCoachData(
      supportScore: supportScore,
      priority: priority,
      summary: _generateSummary(priority, childName, attPct),
      actionPlan: actionPlan,
      academicActions: academicActions,
      emotionalTips: emotionalTips,
      teacherFollowups: teacherFollowups,
    );
  }

  InterventionCoachData _stableResult(String childName) {
    return InterventionCoachData(
      supportScore: 95,
      priority: SupportPriority.low,
      summary: '$childName appears to be on track. Keep up the supportive environment at home.',
      actionPlan: [
        const ActionPlanItem(
          title: 'Maintain Routine',
          description: 'Stable performance. No urgent actions needed this week.',
          icon: Icons.check_circle_outline,
        ),
      ],
      academicActions: ['Continue 30-minute daily revision to maintain consistency.'],
      emotionalTips: [
        'Celebrate progress — not just marks.',
        'Ensure proper sleep before exam weeks.',
      ],
      teacherFollowups: ['Schedule a monthly catch-up with the class teacher.'],
    );
  }

  String _generateSummary(SupportPriority priority, String name, double att) {
    switch (priority) {
      case SupportPriority.low:
        return '$name is stable and progressing well. Focus on motivation and consistency.';
      case SupportPriority.medium:
        return '$name needs some targeted support this week — especially in academic areas and routine.';
      case SupportPriority.high:
        return '$name needs immediate parent involvement. Multiple risk signals detected — act now.';
    }
  }
}
