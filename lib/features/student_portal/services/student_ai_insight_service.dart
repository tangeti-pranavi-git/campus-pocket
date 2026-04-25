import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/student_portal_models.dart';

class StudentAiInsightService {
  Future<StudentInsight> buildInsight({
    required double? attendance,
    required List<double> recentScores,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return _fallbackInsight(attendance: attendance, recentScores: recentScores);
    }

    final endpoint =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

    final prompt = '''
You are an educational assistant. Return concise student insights as JSON with keys:
strengths: string[]
weaknesses: string[]
recommendations: string[]
summary: string

Inputs:
attendancePercentage: ${attendance?.toStringAsFixed(1) ?? 'null'}
recentScores: ${recentScores.map((e) => e.toStringAsFixed(1)).toList()}
''';

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(
          <String, dynamic>{
            'contents': <Map<String, dynamic>>[
              <String, dynamic>{
                'parts': <Map<String, dynamic>>[
                  <String, dynamic>{'text': prompt},
                ],
              },
            ],
          },
        ),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallbackInsight(attendance: attendance, recentScores: recentScores);
      }

      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final text = ((((map['candidates'] as List?)?.firstOrNull as Map?)?['content'] as Map?)?['parts']
              as List?)
          ?.firstOrNull;
      final generated = (text as Map?)?['text'] as String?;
      if (generated == null || generated.isEmpty) {
        return _fallbackInsight(attendance: attendance, recentScores: recentScores);
      }

      final rawJson = _extractJson(generated);
      if (rawJson == null) {
        return _fallbackInsight(attendance: attendance, recentScores: recentScores);
      }

      final parsed = jsonDecode(rawJson) as Map<String, dynamic>;
      final strengths = _stringList(parsed['strengths']);
      final weaknesses = _stringList(parsed['weaknesses']);
      final recommendations = _stringList(parsed['recommendations']);
      final summary = (parsed['summary'] as String?) ??
          'AI generated academic insight is available for this student.';

      if (strengths.isEmpty && weaknesses.isEmpty && recommendations.isEmpty) {
        return _fallbackInsight(attendance: attendance, recentScores: recentScores);
      }

      return StudentInsight(
        strengths: strengths,
        weaknesses: weaknesses,
        recommendations: recommendations,
        generatedByAi: true,
        summary: summary,
      );
    } catch (_) {
      return _fallbackInsight(attendance: attendance, recentScores: recentScores);
    }
  }

  StudentInsight _fallbackInsight({
    required double? attendance,
    required List<double> recentScores,
  }) {
    final avg = recentScores.isEmpty
        ? null
        : recentScores.reduce((a, b) => a + b) / recentScores.length;

    final strengths = <String>[];
    final weaknesses = <String>[];
    final recommendations = <String>[];

    if ((attendance ?? 100) >= 90) {
      strengths.add('Excellent attendance discipline.');
    } else if ((attendance ?? 100) >= 75) {
      strengths.add('Attendance is stable and mostly consistent.');
    } else {
      weaknesses.add('Low attendance is impacting classroom continuity.');
      recommendations.add('Target at least 90% attendance for the next 4 weeks.');
    }

    if ((avg ?? 0) >= 85) {
      strengths.add('Strong academic performance in recent submissions.');
    } else if ((avg ?? 0) >= 65) {
      recommendations.add('Focus on revision for weaker topics to push scores above 80%.');
    } else {
      weaknesses.add('Recent marks indicate foundational gaps in understanding.');
      recommendations.add('Practice previous assignments and seek teacher clarification weekly.');
    }

    if (recentScores.length >= 3) {
      final tail = recentScores.take(3).toList(growable: false);
      final trend = tail.last - tail.first;
      if (trend > 5) {
        strengths.add('Positive score trend over recent assessments.');
      } else if (trend < -5) {
        weaknesses.add('Score trend is declining in latest assessments.');
        recommendations.add('Create a daily 45-minute practice routine for this subject.');
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('Maintain your current study rhythm and review weekly progress.');
    }

    return StudentInsight(
      strengths: strengths,
      weaknesses: weaknesses,
      recommendations: recommendations,
      generatedByAi: false,
      summary:
          'Insight generated by local academic rule engine because Gemini API key is unavailable or request failed.',
    );
  }

  String? _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    return text.substring(start, end + 1);
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value.whereType<String>().where((it) => it.trim().isNotEmpty).toList(growable: false);
  }
}

extension _FirstOrNullExt<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
