import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/parent_portal_controller.dart';
import '../models/parent_portal_models.dart';
import '../widgets/loading_skeletons.dart';

class ParentAnnouncementsScreen extends StatefulWidget {
  const ParentAnnouncementsScreen({super.key, required this.childId});
  final String childId;

  @override
  State<ParentAnnouncementsScreen> createState() => _ParentAnnouncementsScreenState();
}

class _ParentAnnouncementsScreenState extends State<ParentAnnouncementsScreen> {
  List<AnnouncementItem>? _announcements;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final controller = context.read<ParentPortalController>();
    final auth = context.read<AuthController>();
    final schoolId = auth.currentUser?.schoolId;
    if (schoolId == null) return;

    try {
      final items = await controller.loadAnnouncements(schoolId);
      if (mounted) {
        setState(() {
          _announcements = items;
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
        appBar: AppBar(title: const Text('Announcements')),
        body: const DashboardLoadingSkeleton(),
      );
    }

    if (_announcements == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Announcements')),
        body: const Center(child: Text('Failed to load announcements.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _announcements!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _announcements![index];
          
          Color priorityColor = Colors.blue;
          IconData icon = Icons.info;
          if (item.priority == 'HIGH') {
            priorityColor = Colors.orange;
            icon = Icons.warning;
          } else if (item.priority == 'URGENT') {
            priorityColor = Colors.red;
            icon = Icons.error;
          } else if (item.type == 'event') {
            priorityColor = Colors.green;
            icon = Icons.event;
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x331A1412),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: priorityColor.withOpacity(0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: priorityColor.withOpacity(0.2), shape: BoxShape.circle),
                  child: Icon(icon, color: priorityColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          Text(
                            item.createdAt.toLocal().toString().split(' ')[0],
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(item.message, style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
