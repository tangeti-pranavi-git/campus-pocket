import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_routes.dart';
import '../../../src/contexts/auth_controller.dart';
import '../controllers/parent_portal_controller.dart';
import '../models/parent_analytics_models.dart';
import '../models/parent_portal_models.dart';
import '../providers/blind_spot_controller.dart';
import '../widgets/analytics/parent_analytics_widgets.dart';

class ParentBlindSpotDetectorScreen extends StatefulWidget {
  const ParentBlindSpotDetectorScreen({super.key});

  @override
  State<ParentBlindSpotDetectorScreen> createState() =>
      _ParentBlindSpotDetectorScreenState();
}

class _ParentBlindSpotDetectorScreenState
    extends State<ParentBlindSpotDetectorScreen>
    with SingleTickerProviderStateMixin {
  ChildSummary? _selectedChild;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pc = context.read<ParentPortalController>();
      if (pc.dashboard?.children.isNotEmpty ?? false) {
        _selectChild(pc.dashboard!.children.first);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _selectChild(ChildSummary child) {
    setState(() => _selectedChild = child);
    context.read<BlindSpotController>().loadBlindSpotData(child.childId, child.childName);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BlindSpotController>();
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
        backgroundColor: const Color(0xFFE52E71),
        icon: const Icon(Icons.radar_rounded, color: Colors.white),
        label: const Text('Ask AI Analyzer',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),

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
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) => Icon(
                        Icons.radar_rounded,
                        color: Color.lerp(
                            const Color(0xFFE52E71), Colors.white30, _pulseController.value),
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Scanning for hidden patterns...',
                        style: TextStyle(color: Colors.white38, fontSize: 14)),
                  ],
                ),
              ),
            )
          else if (controller.data == null)
            const SliverFillRemaining(
              child: Center(
                child: Text('Select a child to begin analysis',
                    style: TextStyle(color: Colors.white38)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
              sliver: _buildContent(controller.data!),
            ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
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
              colors: [Color(0xFF4A0820), Color(0xFF0A0A0F)],
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
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, __) => Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Color.lerp(
                                    const Color(0xFFE52E71).withOpacity(0.3),
                                    const Color(0xFFE52E71).withOpacity(0.08),
                                    _pulseController.value),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.radar_rounded,
                              color: Color(0xFFE52E71), size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Blind Spot Detector',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900)),
                          Text('Hidden risk intelligence engine',
                              style: TextStyle(color: Colors.white38, fontSize: 12)),
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

  SliverList _buildContent(BlindSpotData data) {
    final color = _severityColor(data.overallSeverity);

    return SliverList(
      delegate: SliverChildListDelegate([
        // ── Risk Score Dial ─────────────────────────────────────────
        _RiskScoreDial(data: data, color: color, pulse: _pulseController),
        const SizedBox(height: 28),

        // ── Active Alerts ───────────────────────────────────────────
        if (data.alerts.isEmpty)
          _NoRisksCard()
        else ...[
          _SectionLabel('ACTIVE HIDDEN ALERTS', Icons.warning_amber_rounded, color),
          const SizedBox(height: 16),
          ...data.alerts.map((alert) => InsightAlertCard(
                title: alert.title,
                message: alert.message,
                color: _severityColor(alert.severity),
                insight: alert.insight,
              )),
        ],

        const SizedBox(height: 24),

        // ── Why It Matters ──────────────────────────────────────────
        if (data.alerts.isNotEmpty) ...[
          _SectionLabel('WHY THESE MATTER', Icons.lightbulb_rounded, Colors.amber),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.amber.withOpacity(0.15)),
            ),
            child: const Text(
              'These patterns are invisible in a standard report card. The Blind Spot Detector looks beneath the surface — at attendance timing, submission patterns, and subject-specific trends — to catch risks 2-3 weeks before they become serious problems.',
              style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.6),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Suggested Actions ───────────────────────────────────────
        ParentTipCard(
          title: '🎯  SUGGESTED PARENT ACTIONS',
          accentColor: color,
          tips: data.suggestedActions,
        ),
        const SizedBox(height: 20),

        // ── AI Insight ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFE52E71).withOpacity(0.08),
                const Color(0xFF8B5CF6).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE52E71).withOpacity(0.15)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI ANALYSIS SUMMARY',
                        style: TextStyle(
                            color: Colors.amber,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    Text(data.aiInsight,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14, height: 1.6)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Teacher Contact Shortcut ────────────────────────────────
        if (data.overallSeverity != BlindSpotSeverity.green) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withOpacity(0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.connect_without_contact_rounded,
                    color: Color(0xFF06B6D4), size: 28),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contact Class Teacher',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Share these findings and ask for a 5-minute feedback call.',
                          style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF06B6D4)),
                ),
              ],
            ),
          ),
        ],
      ]),
    );
  }

  Color _severityColor(BlindSpotSeverity s) {
    switch (s) {
      case BlindSpotSeverity.green:  return const Color(0xFF22C55E);
      case BlindSpotSeverity.yellow: return const Color(0xFFF59E0B);
      case BlindSpotSeverity.red:    return const Color(0xFFEF4444);
    }
  }
}

class _RiskScoreDial extends StatelessWidget {
  final BlindSpotData data;
  final Color color;
  final AnimationController pulse;
  const _RiskScoreDial({required this.data, required this.color, required this.pulse});

  String get _label {
    switch (data.overallSeverity) {
      case BlindSpotSeverity.green:  return '✅  ALL CLEAR — No Hidden Concerns';
      case BlindSpotSeverity.yellow: return '⚠️  CAUTION — Watch Closely';
      case BlindSpotSeverity.red:    return '🔴  CRITICAL — Immediate Attention';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final glow = data.overallSeverity == BlindSpotSeverity.red
            ? color.withOpacity(0.05 + pulse.value * 0.08)
            : Colors.transparent;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1412),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: glow, blurRadius: 30, spreadRadius: 10)],
          ),
          child: Column(
            children: [
              Text('${data.hiddenRiskScore}%',
                  style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: -2)),
              const Text('HIDDEN RISK SCORE',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_label,
                    style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
              if (data.alerts.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('${data.alerts.length} hidden alert${data.alerts.length > 1 ? 's' : ''} detected',
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _NoRisksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withOpacity(0.06),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.15)),
      ),
      child: const Column(
        children: [
          Icon(Icons.shield_outlined, color: Color(0xFF22C55E), size: 52),
          SizedBox(height: 16),
          Text('No Hidden Risks Detected',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 8),
          Text(
            'Your child\'s patterns are consistent and healthy. Keep monitoring weekly to catch early signals.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
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
  const _SectionLabel(this.label, this.icon, this.color);

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
