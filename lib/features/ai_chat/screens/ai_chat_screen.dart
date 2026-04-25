import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/ai_chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../models/chat_message.dart';
import '../widgets/ai_particle_background.dart';
import '../../../src/contexts/auth_controller.dart';

class AiChatScreen extends StatefulWidget {
  final Map<String, dynamic> contextData;
  final String role;
  final String? studentId;
  final String? parentId;
  final String? schoolId;

  const AiChatScreen({
    super.key,
    required this.contextData,
    required this.role,
    this.studentId,
    this.parentId,
    this.schoolId,
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      final name = auth.currentUser?.fullName ?? "there";
      
      final provider = context.read<AiChatProvider>();
      if (provider.messages.isEmpty) {
        String greeting = widget.role == 'parent' 
            ? "Hello $name! I'm your proactive parent assistant. I can help summarize attendance, compare your children's progress, or even draft messages to teachers. How can I assist you today?"
            : "Hi $name! I'm your academic coach. I can help you understand your marks, create study plans, or review pending assignments. What would you like to focus on?";
            
        provider.addMessage(
          ChatMessage(
            isUser: false,
            content: greeting,
            timestamp: DateTime.now(),
          )
        );
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    
    final provider = context.read<AiChatProvider>();
    provider.sendMessage(
      userId: widget.role == 'parent' ? (widget.parentId ?? '') : (widget.studentId ?? ''),
      query: text,
      role: widget.role,
      context: widget.contextData,
    ).then((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiChatProvider>();
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Campus Pocket AI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
            Text(widget.role == 'parent' ? 'Parent Assistant' : 'Academic Coach', 
              style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ],
        ),
        backgroundColor: Colors.black.withOpacity(0.2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white70),
            onPressed: () => provider.clearHistory(),
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: AiParticleBackground(
        child: Column(
          children: [
            const SizedBox(height: 100),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: provider.messages.length,
                itemBuilder: (context, index) {
                  final msg = provider.messages[index];
                  return ChatBubble(
                    message: msg,
                    onConfirmDraft: msg.isDraft ? () => _handleDraftConfirm(context, msg.content) : null,
                  );
                },
              ),
            ),
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: TypingIndicator(),
              ),
            _buildQuickActions(),
            _buildInputArea(theme),
          ],
        ),
      ),
    );
  }

  void _handleDraftConfirm(BuildContext context, String content) {
    // Show a modern bottom sheet for confirmation
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ModernDraftSheet(
        content: content,
        studentId: widget.studentId ?? '',
        parentId: widget.parentId ?? '',
        schoolId: widget.schoolId ?? '',
      ),
    );
  }

  Widget _buildQuickActions() {
    final prompts = widget.role == 'parent'
        ? ["Child Progress?", "Pending Fees?", "Message Teacher", "Attention needed?"]
        : ["Due Assignments?", "Improve Science?", "Study Plan", "Attendance Trend"];
          
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: prompts.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(prompts[index], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
              backgroundColor: Colors.white.withOpacity(0.05),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
              onPressed: () => _handleSubmitted(prompts[index]),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF261D1A),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: _handleSubmitted,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Ask anything...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                      onPressed: () => _handleSubmitted(_textController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double delay = index * 0.2;
            double value = (math.sin((_controller.value * 2 * math.pi) - delay) + 1) / 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3 + (value * 0.7)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

class ModernDraftSheet extends StatelessWidget {
  final String content;
  final String studentId;
  final String parentId;
  final String schoolId;

  const ModernDraftSheet({
    super.key,
    required this.content,
    required this.studentId,
    required this.parentId,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teacherCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1412),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black, blurRadius: 40, spreadRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: theme.colorScheme.secondary.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.mail_outline, color: theme.colorScheme.secondary),
              ),
              const SizedBox(width: 12),
              const Text('Send Teacher Message', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: teacherCtrl,
            decoration: const InputDecoration(labelText: 'Teacher Name', hintText: 'e.g. Mr. Sharma'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: subjectCtrl,
            decoration: const InputDecoration(labelText: 'Subject', hintText: 'e.g. Mathematics Query'),
          ),
          const SizedBox(height: 24),
          const Text('Message Body', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16)),
            child: Text(content.contains('<DRAFT>') ? content.split('<DRAFT>')[1].split('</DRAFT>')[0].trim() : content, 
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<AiChatProvider>().confirmTeacherMessageDraft(
                  subject: subjectCtrl.text.isEmpty ? 'Update Request' : subjectCtrl.text,
                  message: content,
                  teacherName: teacherCtrl.text.isEmpty ? 'Class Teacher' : teacherCtrl.text,
                  parentId: parentId,
                  studentId: studentId,
                  schoolId: schoolId,
                );
                Navigator.pop(context);
              },
              child: const Text('SEND SECURELY'),
            ),
          ),
        ],
      ),
    );
  }
}
