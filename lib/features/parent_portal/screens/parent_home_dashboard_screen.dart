import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_routes.dart';
import '../../../src/contexts/auth_controller.dart';
import '../controllers/parent_portal_controller.dart';
import '../models/parent_portal_models.dart';
import '../widgets/empty_children_state.dart';
import '../widgets/error_retry_widget.dart';
import '../widgets/loading_skeletons.dart';
import '../widgets/notification_badge.dart';
import '../../../controllers/notification_controller.dart';

class ParentHomeDashboardScreen extends StatefulWidget {
  const ParentHomeDashboardScreen({super.key});

  @override
  State<ParentHomeDashboardScreen> createState() => _ParentHomeDashboardScreenState();
}

class _ParentHomeDashboardScreenState extends State<ParentHomeDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  ChildSummary? _selectedChild;
  bool _showFeatureGrid = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      context.read<ParentPortalController>().loadDashboard(user: auth.currentUser);
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _selectChild(ChildSummary child) {
    setState(() {
      _selectedChild = child;
      _showFeatureGrid = true;
    });
    context.read<ParentPortalController>().selectChild(child.childId);
    // Navigate to the full student portal screen
    context.push('/parent/student/${child.childId}');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final controller = context.watch<ParentPortalController>();
    final dashboard = controller.dashboard;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0B0A),
      body: switch (controller.state) {
        ParentPortalLoadState.loading => const DashboardLoadingSkeleton(),
        ParentPortalLoadState.error => ErrorRetryWidget(
            message: controller.errorMessage ?? 'Failed to load dashboard',
            onRetry: () => controller.loadDashboard(user: auth.currentUser, forceRefresh: true),
          ),
        _ => _buildLoaded(context, auth, controller, dashboard),
      },
      floatingActionButton: (controller.state == ParentPortalLoadState.success ||
              controller.state == ParentPortalLoadState.refreshing)
          ? FloatingActionButton.extended(
              onPressed: () {
                final child = _selectedChild ?? dashboard?.children.firstOrNull;
                context.push(AppRoutes.aiChat, extra: {
                  'role': 'parent',
                  'contextData': {
                    'parentName': dashboard?.parentName,
                    'children': dashboard?.children.map((c) => {
                          'name': c.childName,
                          'attendance': c.attendancePercentage,
                          'grade': c.averageGradePercentage,
                          'feeStatus': c.feeStatus?.name,
                        }).toList(),
                    'selectedChildId': child?.childId,
                  },
                  'studentId': child?.childId.toString(),
                  'parentId': auth.currentUser?.id?.toString(),
                  'schoolId': auth.currentUser?.schoolId?.toString(),
                });
              },
              backgroundColor: const Color(0xFFFF8A00),
              icon: const Icon(Icons.auto_awesome, color: Colors.black),
              label: const Text('Ask AI', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    AuthController auth,
    ParentPortalController controller,
    DashboardOverview? dashboard,
  ) {
    final data = dashboard ??
        const DashboardOverview(parentName: 'Parent', children: <ChildSummary>[], criticalAlerts: 0);

    return RefreshIndicator(
      color: const Color(0xFFFF8A00),
      onRefresh: () => controller.refresh(user: auth.currentUser),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Premium Header ──────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader(context, data, auth, controller)),

          // ── Section Label ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8A00),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Your Children',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${data.children.length} linked',
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          // ── Beautiful Child Cards ────────────────────────────────────────
          if (data.children.isEmpty)
            const SliverFillRemaining(hasScrollBody: false, child: EmptyChildrenState())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: data.children.length,
                itemBuilder: (ctx, i) =>
                    _ChildCard(child: data.children[i], onTap: () => _selectChild(data.children[i])),
              ),
            ),

          // ── Feature Grid (appears after child selection) ─────────────────
          if (_showFeatureGrid && _selectedChild != null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE52E71),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedChild!.childName}\'s Portal',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          Text(
                            _selectedChild!.classLabel,
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _showFeatureGrid = false;
                        _selectedChild = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                delegate: SliverChildListDelegate([
                  _FeatureTile(title: 'Attendance', icon: Icons.how_to_reg_rounded, color: const Color(0xFF22C55E),
                      onTap: () => context.push('${AppRoutes.parentAttendance}?childId=${_selectedChild!.childId}')),
                  _FeatureTile(title: 'Timetable', icon: Icons.schedule_rounded, color: const Color(0xFF3B82F6),
                      onTap: () => context.push('${AppRoutes.parentTimetable}?childId=${_selectedChild!.childId}')),
                  _FeatureTile(title: 'Report Card', icon: Icons.bar_chart_rounded, color: const Color(0xFFFF8A00),
                      onTap: () => context.push('${AppRoutes.parentReportCard}?childId=${_selectedChild!.childId}')),
                  _FeatureTile(title: 'Announcements', icon: Icons.campaign_rounded, color: const Color(0xFFEC4899),
                      onTap: () => context.push('${AppRoutes.parentAnnouncements}?childId=${_selectedChild!.childId}')),
                  _FeatureTile(title: 'Assignments', icon: Icons.assignment_rounded, color: const Color(0xFFA855F7),
                      onTap: () => context.push('${AppRoutes.parentAssignments}?childId=${_selectedChild!.childId}')),
                  _FeatureTile(title: 'Holidays', icon: Icons.event_note_rounded, color: const Color(0xFF14B8A6),
                      onTap: () => context.push('${AppRoutes.parentHolidays}?childId=${_selectedChild!.childId}')),
                  _FeatureTile(title: 'Fee Details', icon: Icons.account_balance_wallet_rounded,
                      color: _selectedChild!.feeStatus == FeeStatusType.overdue ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                      badge: _selectedChild!.feeStatus == FeeStatusType.overdue ? '!' : null,
                      onTap: () => context.push('${AppRoutes.parentFees}?childId=${_selectedChild!.childId}')),
                  _FeatureTile(title: 'Message Teacher', icon: Icons.message_rounded, color: const Color(0xFF06B6D4),
                      onTap: () => context.push('${AppRoutes.parentMessages}?childId=${_selectedChild!.childId}')),
                  _FeatureTile(title: 'Voice Assistant', icon: Icons.mic_rounded, color: const Color(0xFFFF8A00),
                      onTap: () => context.push(AppRoutes.parentVoiceAssistant, extra: {
                            'contextData': {
                              'selectedChild': _selectedChild!.childName,
                              'attendance': _selectedChild!.attendancePercentage,
                              'grade': _selectedChild!.averageGradePercentage,
                            },
                            'studentId': _selectedChild!.childId.toString(),
                            'parentId': auth.currentUser?.id?.toString(),
                            'schoolId': auth.currentUser?.schoolId?.toString(),
                          })),
                  _FeatureTile(title: 'Intervention Coach', icon: Icons.psychology_rounded, color: const Color(0xFF8B5CF6),
                      onTap: () => context.push(AppRoutes.parentInterventionCoach)),
                  _FeatureTile(title: 'Blind Spot Detector', icon: Icons.radar_rounded, color: const Color(0xFFE52E71),
                      onTap: () => context.push(AppRoutes.parentBlindSpotDetector)),
                  _FeatureTile(title: 'Full Profile', icon: Icons.person_search_rounded, color: const Color(0xFF64748B),
                      onTap: () => context.go('/parent/child/${_selectedChild!.childId}')),
                ]),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    DashboardOverview data,
    AuthController auth,
    ParentPortalController controller,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0F0A), Color(0xFF2D1020), Color(0xFF0F0B0A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: hamburger + logo + bell + profile
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Campus Pocket',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Consumer<NotificationController>(
                    builder: (context, notificationCtrl, _) {
                      return NotificationBadge(
                        count: notificationCtrl.unreadCount,
                        child: IconButton(
                          onPressed: () => context.push('/notifications'),
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    onPressed: () => context.go('/profile'),
                    icon: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF8A00), width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Color(0xFF2D1020),
                        child: Icon(Icons.person, color: Color(0xFFFF8A00), size: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Welcome text
              Text(
                'Welcome back,',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
              ),
              Text(
                data.parentName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              // Summary pills
              Row(
                children: [
                  _SummaryPill(
                    icon: Icons.people_outline_rounded,
                    label: '${data.children.length} Children',
                    color: const Color(0xFFFF8A00),
                  ),
                  const SizedBox(width: 12),
                  if (data.criticalAlerts > 0)
                    _SummaryPill(
                      icon: Icons.warning_amber_rounded,
                      label: '${data.criticalAlerts} Alert${data.criticalAlerts > 1 ? 's' : ''}',
                      color: const Color(0xFFEF4444),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Premium Child Card
// ─────────────────────────────────────────────────────────────
class _ChildCard extends StatefulWidget {
  const _ChildCard({required this.child, required this.onTap});
  final ChildSummary child;
  final VoidCallback onTap;

  @override
  State<_ChildCard> createState() => _ChildCardState();
}

class _ChildCardState extends State<_ChildCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<Color> get _gradient {
    final name = widget.child.childName;
    final hue = (name.codeUnitAt(0) * 37) % 360;
    return [
      HSLColor.fromAHSL(1, hue.toDouble(), 0.7, 0.25).toColor(),
      HSLColor.fromAHSL(1, (hue + 40).toDouble(), 0.6, 0.15).toColor(),
    ];
  }

  Color get _accentColor {
    final name = widget.child.childName;
    final hue = (name.codeUnitAt(0) * 37) % 360;
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.9, 0.6).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final attendance = widget.child.attendancePercentage ?? 0;
    final grade = widget.child.averageGradePercentage ?? 0;
    final feeAlert = widget.child.hasCriticalFeeAlert;

    return GestureDetector(
      onTapDown: (_) => _animController.forward(),
      onTapUp: (_) {
        _animController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _animController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: _gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _accentColor.withOpacity(0.2), width: 1.5),
            boxShadow: [BoxShadow(color: _accentColor.withOpacity(0.08), blurRadius: 24, spreadRadius: 4)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _accentColor.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(
                          widget.child.childName.isNotEmpty ? widget.child.childName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.child.childName,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(widget.child.classLabel, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                        ],
                      ),
                    ),
                    if (feeAlert)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                        ),
                        child: const Text('Fee Due', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, color: _accentColor, size: 24),
                  ],
                ),
                const SizedBox(height: 24),
                // Stats row
                Row(
                  children: [
                    Expanded(child: _StatBar(label: 'Attendance', value: attendance / 100, displayText: '${attendance.toStringAsFixed(1)}%', color: attendance >= 75 ? const Color(0xFF22C55E) : const Color(0xFFEF4444))),
                    const SizedBox(width: 16),
                    Expanded(child: _StatBar(label: 'Avg Grade', value: grade / 100, displayText: '${grade.toStringAsFixed(1)}%', color: grade >= 60 ? const Color(0xFFFF8A00) : const Color(0xFFEF4444))),
                  ],
                ),
                const SizedBox(height: 20),
                // Quick stats row
                Row(
                  children: [
                    _QuickStat(icon: Icons.calendar_today_rounded, value: '${widget.child.totalSessions}', label: 'Sessions'),
                    const SizedBox(width: 16),
                    _QuickStat(icon: Icons.check_circle_outline_rounded, value: '${widget.child.presentCount}', label: 'Present'),
                    const SizedBox(width: 16),
                    _QuickStat(icon: Icons.cancel_outlined, value: '${widget.child.absentCount}', label: 'Absent'),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _accentColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        'View Portal',
                        style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({required this.label, required this.value, required this.displayText, required this.color});
  final String label;
  final double value;
  final String displayText;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            Text(displayText, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 14),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Feature Tile (3-column grid)
// ─────────────────────────────────────────────────────────────
class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, height: 1.3),
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                  child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
