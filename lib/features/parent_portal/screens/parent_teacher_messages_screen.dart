import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/parent_portal_controller.dart';
import '../models/parent_portal_models.dart';
import '../widgets/loading_skeletons.dart';

class ParentTeacherMessagesScreen extends StatefulWidget {
  const ParentTeacherMessagesScreen({super.key, required this.childId});
  final String childId;

  @override
  State<ParentTeacherMessagesScreen> createState() => _ParentTeacherMessagesScreenState();
}

class _ParentTeacherMessagesScreenState extends State<ParentTeacherMessagesScreen> {
  List<MessageItem>? _messages;
  List<Map<String, String>> _availableTeachers = [];
  bool _isLoading = true;
  
  Map<String, String>? _selectedTeacher;
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final controller = context.read<ParentPortalController>();
    final auth = context.read<AuthController>();
    final parentId = auth.currentUser?.id;
    final cId = int.tryParse(widget.childId);
    if (parentId == null || cId == null) return;

    try {
      final items = await controller.loadMessages(parentId, cId);
      final teachers = await controller.getTeachers(cId);
      if (mounted) {
        setState(() {
          _messages = items;
          _availableTeachers = teachers;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNewMessageDialog() {
    // Reset selection when opening dialog
    _selectedTeacher = null;
    _messageController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1412),
              title: const Text('New Message', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Map<String, String>>(
                      value: _selectedTeacher,
                      decoration: const InputDecoration(labelText: 'Select Teacher & Subject'),
                      dropdownColor: const Color(0xFF261D1A),
                      items: _availableTeachers.map((teacher) {
                        return DropdownMenuItem(
                          value: teacher,
                          child: Text(
                            '${teacher['teacherName']} — ${teacher['subject']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          _selectedTeacher = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Message', hintText: 'Type your message here...'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_selectedTeacher == null || _messageController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a teacher and enter a message.')));
                      return;
                    }

                    final auth = context.read<AuthController>();
                    final controller = context.read<ParentPortalController>();
                    final parentId = auth.currentUser?.id ?? 0;
                    final schoolId = auth.currentUser?.schoolId ?? 1;
                    final childId = int.tryParse(widget.childId) ?? 0;

                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    
                    await controller.sendMessage(
                      schoolId: schoolId,
                      parentId: parentId,
                      studentId: childId,
                      teacherName: _selectedTeacher!['teacherName']!,
                      subject: _selectedTeacher!['subject']!,
                      message: _messageController.text.trim(),
                    );
                    
                    await _loadData();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A00)),
                  child: const Text('Send'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: const DashboardLoadingSkeleton(),
      );
    }

    if (_messages == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: const Center(child: Text('Failed to load messages.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewMessageDialog,
        backgroundColor: const Color(0xFFE52E71),
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
      body: _messages!.isEmpty 
        ? const Center(child: Text('No messages yet. Send one to a teacher!', style: TextStyle(color: Colors.white54)))
        : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _messages!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final msg = _messages![index];
          final isUnread = msg.status == 'UNREAD';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x331A1412),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isUnread ? const Color(0xFFFF8A00) : const Color(0x1AFFFFFF), width: isUnread ? 1.5 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('To/From: ${msg.teacherName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(msg.createdAt.toLocal().toString().split(' ')[0], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Subject: ${msg.subject}', style: const TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Text(msg.message, style: const TextStyle(color: Colors.white70)),
                if (msg.reply != null) ...[
                  const Divider(color: Color(0x1AFFFFFF), height: 30),
                  const Text('Reply:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white54)),
                  const SizedBox(height: 4),
                  Text(msg.reply!, style: const TextStyle(color: Colors.white)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
