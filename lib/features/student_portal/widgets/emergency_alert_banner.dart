import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../controllers/notification_controller.dart';
import '../../../models/notification_model.dart';

class EmergencyAlertBanner extends StatefulWidget {
  const EmergencyAlertBanner({super.key});

  @override
  State<EmergencyAlertBanner> createState() => _EmergencyAlertBannerState();
}

class _EmergencyAlertBannerState extends State<EmergencyAlertBanner> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      final controller = context.read<NotificationController>();
      final unreadAlerts = _getSortedAlerts(controller.notifications);
      if (unreadAlerts.length > 1) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % unreadAlerts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<NotificationItem> _getSortedAlerts(List<NotificationItem> notifications) {
    final unread = notifications.where((n) => !n.isRead).toList();
    // Sort by priority: high, medium, low, then by date
    unread.sort((a, b) {
      final pA = _priorityScore(a.priority);
      final pB = _priorityScore(b.priority);
      if (pA != pB) return pB.compareTo(pA); // higher score first
      return b.createdAt.compareTo(a.createdAt); // newer first
    });
    return unread;
  }

  int _priorityScore(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  Color _getBannerColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444); // Red
      case 'medium':
        return const Color(0xFFF97316); // Orange
      case 'low':
        return const Color(0xFF3B82F6); // Blue
      default:
        return const Color(0xFF10B981); // Green
    }
  }

  IconData _getBannerIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Icons.warning_rounded;
      case 'medium':
        return Icons.info_outline_rounded;
      case 'low':
        return Icons.notifications_active_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationController>(
      builder: (context, controller, child) {
        final alerts = _getSortedAlerts(controller.notifications);

        if (alerts.isEmpty) {
          return _buildMotivationalBanner(context);
        }

        // Ensure current index is valid
        if (_currentIndex >= alerts.length) {
          _currentIndex = 0;
        }

        final currentAlert = alerts[_currentIndex];
        final color = _getBannerColor(currentAlert.priority);

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: GestureDetector(
            key: ValueKey(currentAlert.id),
            onTap: () {
              if (currentAlert.redirectRoute != null && currentAlert.redirectRoute!.isNotEmpty) {
                context.push(currentAlert.redirectRoute!);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.9),
                    color.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(
                  color: color.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getBannerIcon(currentAlert.priority),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentAlert.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentAlert.message,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (currentAlert.redirectRoute != null && currentAlert.redirectRoute!.isNotEmpty)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withOpacity(0.8),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMotivationalBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1), // Gentle green
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All clear today',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'No urgent alerts right now. Keep up the good work! 🌟',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF10B981).withOpacity(0.8),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
