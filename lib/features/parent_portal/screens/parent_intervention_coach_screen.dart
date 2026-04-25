import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_routes.dart';
import '../../../src/contexts/auth_controller.dart';
import '../controllers/parent_portal_controller.dart';
import '../models/parent_analytics_models.dart';
import '../models/parent_portal_models.dart';
import '../providers/parent_intervention_controller.dart';
import '../widgets/analytics/parent_analytics_widgets.dart';

class ParentInterventionCoachScreen extends StatefulWidget {
  const ParentInterventionCoachScreen({super.key});

  @override
  State<ParentInterventionCoachScreen> createState() =>
      _ParentInterventionCoachScreenState();
}

class _ParentInterventionCoachScreenState
    extends State<ParentInterventionCoachScreen>
    with SingleTickerProviderStateMixin {
  ChildSummary? _selectedChild;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
          ..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pc = context.read<ParentPortalController>();
      if (pc.dashboard?.children.isNotEmpty ?? false) {
        _selectChild(pc.dashboard!.children.first);
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _selectChild(ChildSummary child) {
    setState(() => _selectedChild = child);
    context.read<ParentInterventionController>().loadInterventionData(
        child.childId, child.childName);
    _fadeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ParentInterventionController>();
    final parentController = context.watch<ParentPortalController>();
    final children = parentController.dashboard?.children ?? [];
    final auth = context.read<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.aiChat, extra: {
          'role': 'parent',
          'contextData': {
            'parentName': auth.currentUser?.username,
            'selectedChild': _selectedChild?.childName,
            'children': children.map((c) => {
                  'name': c.childName,
                  'attendance': c.attendancePercentage,
                  'grade': c.averageGradePercentage,
                  'feeStatus': c.feeStatus.name,
                }).toList(),
          },
          'parentId': auth.currentUser?.id?.toString(),
          'schoolId': auth.currentUser?.schoolId?.toString(),
        }),
        backgroundColor: const Color(0xFF8B5CF6),
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text('Ask AI Coach',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),

          // ── Child Selector ──────────────────────────────────────────
          if (children.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: ChildSelectorCard(
                  children: children,
                  selectedId: _selectedChild?.childId ?? 0,
                  onSelected: _selectChild,
                ),
              ),
            ),

          // ── Content ─────────────────────────────────────────────────
          if (controller.isLoading)
            const SliverFillRemaining(
                child: Center(child: _LoadingIndicator()))
          else if (controller.data == null)
            const SliverFillRemaining(
                child: Center(child: _EmptyState()))
          else
            SliverFadeTransition(
              opacity: _fadeController,
              sliver: SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
                sliver: _buildContent(controller.data!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: const Color(0xFF0A0A0F),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2D1B69), Color(0xFF0A0A0F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 44),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.psychology_rounded,
                            color: Color(0xFF8B5CF6), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Intervention Coach',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900)),
                          Text('Personalized weekly action plan',
                              style:
                                  TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  SliverList _buildContent(InterventionCoachData data) {
    final color = _priorityColor(data.priority);

    return SliverList(
      delegate: SliverChildListDelegate([
        // ── Support Score Card ──────────────────────────────────────
        _ScoreGaugeCard(data: data, color: color),
        const SizedBox(height: 28),

        // ── Action Plan ─────────────────────────────────────────────
        _SectionLabel(label: 'THIS WEEK\'S ACTION PLAN', icon: Icons.checklist_rounded, color: const Color(0xFF8B5CF6)),
        const SizedBox(height: 16),
        ...data.actionPlan.asMap().entries.map((e) => _ActionStep(
              step: e.key + 1,
              item: e.value,
              color: color,
            )),

        const SizedBox(height: 28),

        // ── Academic Steps ──────────────────────────────────────────
        ParentTipCard(
          title: '📚  ACADEMIC STEPS',
          accentColor: const Color(0xFFFF8A00),
          tips: data.academicActions,
        ),
        const SizedBox(height: 20),

        // ── Emotional Support ───────────────────────────────────────
        ParentTipCard(
          title: '💙  EMOTIONAL SUPPORT',
          accentColor: const Color(0xFFA855F7),
          tips: data.emotionalTips,
        ),
        const SizedBox(height: 20),

        // ── Teacher Follow-Up ───────────────────────────────────────
        ParentTipCard(
          title: '👩‍🏫  TEACHER FOLLOW-UP',
          accentColor: const Color(0xFF3B82F6),
          tips: data.teacherFollowups,
        ),
        const SizedBox(height: 20),

        // ── Progress reminder banner ────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: Color(0xFF8B5CF6)),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Progress Check Reminder',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Revisit this plan every Sunday evening. Track which actions you completed.',
                        style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Color _priorityColor(SupportPriority p) {
    switch (p) {
      case SupportPriority.low:    return const Color(0xFF22C55E);
      case SupportPriority.medium: return const Color(0xFFF59E0B);
      case SupportPriority.high:   return const Color(0xFFEF4444);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Score Gauge Card
// ─────────────────────────────────────────────────────────────
class _ScoreGaugeCard extends StatelessWidget {
  final InterventionCoachData data;
  final Color color;
  const _ScoreGaugeCard({required this.data, required this.color});

  String get _priorityLabel {
    switch (data.priority) {
      case SupportPriority.low:    return '✅  CHILD IS STABLE';
      case SupportPriority.medium: return '⚠️  SOME INTERVENTION NEEDED';
      case SupportPriority.high:   return '🔴  IMMEDIATE SUPPORT ADVISED';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), const Color(0xFF1A1412)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: CircularProgressIndicator(
                  value: data.supportScore / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${data.supportScore}',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
                  Text('/100', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_priorityLabel,
                      style: TextStyle(
                          color: color, fontSize: 11, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 10),
                Text(data.summary,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Action Step
// ─────────────────────────────────────────────────────────────
class _ActionStep extends StatelessWidget {
  final int step;
  final ActionPlanItem item;
  final Color color;
  const _ActionStep({required this.step, required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1412),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$step',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(item.icon, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item.title,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(item.description,
                    style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SectionLabel({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
      ],
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: Color(0xFF8B5CF6)),
        const SizedBox(height: 16),
        Text('Generating your action plan...',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.family_restroom, color: Colors.white24, size: 64),
        SizedBox(height: 16),
        Text('No children linked yet', style: TextStyle(color: Colors.white38, fontSize: 16)),
      ],
    );
  }
}
