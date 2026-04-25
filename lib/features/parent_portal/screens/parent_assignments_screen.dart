import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/parent_portal_controller.dart';
import '../models/parent_portal_models.dart';
import '../widgets/loading_skeletons.dart';

class ParentAssignmentsScreen extends StatefulWidget {
  const ParentAssignmentsScreen({super.key, required this.childId});
  final String childId;

  @override
  State<ParentAssignmentsScreen> createState() => _ParentAssignmentsScreenState();
}

class _ParentAssignmentsScreenState extends State<ParentAssignmentsScreen> {
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
        appBar: AppBar(title: const Text('Assignments')),
        body: const DashboardLoadingSkeleton(),
      );
    }

    if (_childDetail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assignments')),
        body: const Center(child: Text('Failed to load assignments.')),
      );
    }

    final assignments = _childDetail!.recentAssignments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Assignments', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (assignments.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No recent assignments.')))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: assignments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final assignment = assignments[index];
                  return ListTile(
                    tileColor: const Color(0x331A1412),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: Text(assignment.assignmentTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${assignment.classroomName} • Submitted: ${assignment.submittedAt.toLocal().toString().split(' ')[0]}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${assignment.score}/${assignment.total}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${assignment.percentage.toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFFFF8A00))),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
