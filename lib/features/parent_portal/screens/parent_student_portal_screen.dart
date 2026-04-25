import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_routes.dart';
import '../../../src/contexts/auth_controller.dart';
import '../controllers/parent_portal_controller.dart';
import '../models/parent_portal_models.dart';
import '../widgets/loading_skeletons.dart';

class ParentStudentPortalScreen extends StatefulWidget {
  final int childId;
  const ParentStudentPortalScreen({super.key, required this.childId});

  @override
  State<ParentStudentPortalScreen> createState() => _ParentStudentPortalScreenState();
}

class _ParentStudentPortalScreenState extends State<ParentStudentPortalScreen> {
  int _selectedTab = 0;
  ChildDetailData? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final auth = context.read<AuthController>();
      final data = await context.read<ParentPortalController>().loadChildDetail(
        user: auth.currentUser!,
        childId: widget.childId,
      );
      if (mounted) setState(() { _detail = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = context.watch<ParentPortalController>().dashboard?.children
        .where((c) => c.childId == widget.childId).firstOrNull;
    final auth = context.read<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0B0A),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(AppRoutes.aiChat, extra: {
            'role': 'parent',
            'contextData': {
              'parentName': auth.currentUser?.username ?? 'Parent',
              'selectedChild': child?.childName,
              'children': [{
                'name': child?.childName,
                'attendance': child?.attendancePercentage,
                'grade': child?.averageGradePercentage,
                'feeStatus': child?.feeStatus.name,
              }],
              'selectedChildId': widget.childId,
            },
            'studentId': widget.childId.toString(),
            'parentId': auth.currentUser?.id?.toString(),
            'schoolId': auth.currentUser?.schoolId?.toString(),
          });
        },
        backgroundColor: const Color(0xFFFF8A00),
        icon: const Icon(Icons.auto_awesome, color: Colors.black),
        label: const Text('Ask AI', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const DashboardLoadingSkeleton()
          : _buildBody(context, child),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedTab,
        onTap: (i) {
          setState(() => _selectedTab = i);
          _onNavTap(i, child);
        },
        childId: widget.childId,
      ),
    );
  }

  void _onNavTap(int i, ChildSummary? child) {
    switch (i) {
      case 0: context.go(AppRoutes.parentHome); break;
      case 1: break; // stay on screen, show notifications
      case 2:
        final auth = context.read<AuthController>();
        context.push(AppRoutes.parentVoiceAssistant, extra: {
          'contextData': {'selectedChild': child?.childName},
          'studentId': widget.childId.toString(),
          'parentId': auth.currentUser?.id?.toString(),
          'schoolId': auth.currentUser?.schoolId?.toString(),
        });
        break;
      case 3: context.push('${AppRoutes.parentHolidays}?childId=${widget.childId}'); break;
      case 4: context.go('/profile'); break;
    }
  }

  Widget _buildBody(BuildContext context, ChildSummary? child) {
    final attendance = child?.attendancePercentage ?? 0;
    final grade = child?.averageGradePercentage ?? 0;

    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────────────────────
        SliverToBoxAdapter(child: _buildHeader(context, child)),

        // ── Pie Charts ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Row(
              children: [
                Expanded(child: _PieCard(
                  title: 'Avg Marks',
                  value: grade,
                  color: const Color(0xFFFF8A00),
                  bgColor: const Color(0xFF1A1412),
                )),
                const SizedBox(width: 12),
                Expanded(child: _PieCard(
                  title: 'Attendance',
                  value: attendance,
                  color: const Color(0xFF22C55E),
                  bgColor: const Color(0xFF1A1412),
                )),
              ],
            ),
          ),
        ),

        // ── Section Label ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Row(children: [
              Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFFFF8A00), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              const Text('Quick Access', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
            ]),
          ),
        ),

        // ── Feature Grid ─────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildListDelegate([
              _GridTile(icon: Icons.how_to_reg_rounded, label: 'Attendance', color: const Color(0xFF22C55E),
                  onTap: () => context.push('${AppRoutes.parentAttendance}?childId=${widget.childId}')),
              _GridTile(icon: Icons.schedule_rounded, label: 'Time Table', color: const Color(0xFF3B82F6),
                  onTap: () => context.push('${AppRoutes.parentTimetable}?childId=${widget.childId}')),
              _GridTile(icon: Icons.bar_chart_rounded, label: 'Report Card', color: const Color(0xFFFF8A00),
                  onTap: () => context.push('${AppRoutes.parentReportCard}?childId=${widget.childId}')),
              _GridTile(icon: Icons.assignment_rounded, label: 'Homework', color: const Color(0xFFA855F7),
                  onTap: () => context.push('${AppRoutes.parentAssignments}?childId=${widget.childId}')),
              _GridTile(icon: Icons.account_balance_wallet_rounded, label: 'Fee Details', color: const Color(0xFFF59E0B),
                  onTap: () => context.push('${AppRoutes.parentFees}?childId=${widget.childId}')),
              _GridTile(icon: Icons.message_rounded, label: 'Messages', color: const Color(0xFF06B6D4),
                  onTap: () => context.push('${AppRoutes.parentMessages}?childId=${widget.childId}')),
              _GridTile(icon: Icons.campaign_rounded, label: 'Alerts', color: const Color(0xFFE52E71),
                  onTap: () => context.push('${AppRoutes.parentAnnouncements}?childId=${widget.childId}')),
              _GridTile(icon: Icons.psychology_rounded, label: 'Intervention', color: const Color(0xFF8B5CF6),
                  onTap: () => context.push(AppRoutes.parentInterventionCoach)),
              _GridTile(icon: Icons.radar_rounded, label: 'Blind Spots', color: const Color(0xFFE52E71),
                  onTap: () => context.push(AppRoutes.parentBlindSpotDetector)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ChildSummary? child) {
    final name = child?.childName ?? 'Student';
    final hue = name.isNotEmpty ? (name.codeUnitAt(0) * 37 % 360).toDouble() : 200.0;
    final accent = HSLColor.fromAHSL(1, hue, 0.8, 0.6).toColor();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HSLColor.fromAHSL(1, hue, 0.6, 0.12).toColor(),
            const Color(0xFF0F0B0A),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              // Top bar
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => context.go(AppRoutes.parentHome),
                  ),
                  const Expanded(child: Text('Student Portal', style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 1.5))),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
                    onPressed: _load,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Student profile card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: accent.withOpacity(0.4), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(color: accent, fontSize: 28, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(child?.classLabel ?? '', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(children: [
                            _InfoPill('ID #${child?.childId ?? '--'}', accent),
                            const SizedBox(width: 8),
                            _InfoPill('School ${child?.schoolId ?? '--'}', Colors.white38),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _InfoPill(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

// ── Pie Chart Card ────────────────────────────────────────────────────────────
class _PieCard extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final Color bgColor;

  const _PieCard({required this.title, required this.value, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    final pct = value.clamp(0.0, 100.0);
    final remaining = 100.0 - pct;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
                    sections: [
                      PieChartSectionData(
                        value: pct,
                        color: color,
                        radius: 18,
                        title: '',
                        badgePositionPercentageOffset: 0,
                      ),
                      PieChartSectionData(
                        value: remaining > 0 ? remaining : 0,
                        color: Colors.white10,
                        radius: 14,
                        title: '',
                      ),
                    ],
                  ),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${pct.toStringAsFixed(0)}%',
                      style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid Tile ─────────────────────────────────────────────────────────────────
class _GridTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GridTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, height: 1.2)),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Navigation ─────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final int childId;

  const _BottomNav({required this.selectedIndex, required this.onTap, required this.childId});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.notifications_outlined, 'Alerts'),
      (Icons.mic_rounded, 'Voice'),
      (Icons.event_note_rounded, 'Holidays'),
      (Icons.person_outline_rounded, 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1412),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final (icon, label) = items[i];
              final isSelected = selectedIndex == i;
              final color = isSelected ? const Color(0xFFFF8A00) : Colors.white38;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 22),
                      const SizedBox(height: 3),
                      Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
