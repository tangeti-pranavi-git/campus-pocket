import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/student_portal_controller.dart';
import '../models/student_portal_models.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  State<StudentAssignmentsScreen> createState() => _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen> {
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
        appBar: AppBar(title: const Text('Assignments')),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF00B4D8))),
      );
    }

    if (_assignments == null || _assignments!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Assignments'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        ),
        body: const Center(child: Text('No assignments available.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _assignments!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _assignments![index];
          final isPending = item.status == 'Pending';
          
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
                decoration: BoxDecoration(color: isPending ? const Color(0x1AFF8A00) : const Color(0x1A00B4D8), shape: BoxShape.circle),
                child: Icon(Icons.assignment, color: isPending ? const Color(0xFFFF8A00) : const Color(0xFF00B4D8)),
              ),
              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: Text('${item.subject}\nDue: ${DateFormat('MMM d, yyyy').format(item.dueDate)}', style: const TextStyle(height: 1.5)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.status,
                    style: TextStyle(
                      color: isPending ? const Color(0xFFFF8A00) : Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  if (item.score != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${item.score}/${item.totalScore}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
