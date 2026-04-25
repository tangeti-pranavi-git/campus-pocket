import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../controllers/notification_controller.dart';
import '../../models/notification_model.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationController>();
    final notifications = controller.notifications;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0B0A),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () => controller.markAllAsRead(),
              child: const Text('Mark all read', style: TextStyle(color: Color(0xFFFF8A00))),
            ),
        ],
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8A00)))
          : notifications.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return _buildNotificationCard(context, controller, item);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('No new notifications', style: TextStyle(color: Colors.white54, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationController controller, NotificationItem item) {
    final isHighPriority = item.priority == 'high';
    
    IconData getIcon() {
      switch (item.type) {
        case 'exam': return Icons.assignment_rounded;
        case 'fee': return Icons.account_balance_wallet_rounded;
        case 'attendance': return Icons.warning_rounded;
        case 'report': return Icons.bar_chart_rounded;
        case 'homework': return Icons.book_rounded;
        case 'timetable': return Icons.calendar_month_rounded;
        case 'assignment': return Icons.assignment_turned_in_rounded;
        default: return Icons.notifications_rounded;
      }
    }

    return Dismissible(
      key: Key(item.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => controller.deleteNotification(item.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: () {
          if (!item.isRead) controller.markAsRead(item.id);
          if (item.redirectRoute != null && item.redirectRoute!.isNotEmpty) {
            context.push(item.redirectRoute!);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: item.isRead ? const Color(0xFF1A1412) : const Color(0xFF261D1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighPriority && !item.isRead ? const Color(0xFFFF3366).withOpacity(0.5) : const Color(0x1AFFFFFF),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isHighPriority && !item.isRead 
                      ? const Color(0x33FF3366) 
                      : const Color(0x33FF8A00),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  getIcon(),
                  color: isHighPriority && !item.isRead ? const Color(0xFFFF3366) : const Color(0xFFFF8A00),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              color: item.isRead ? Colors.white70 : Colors.white,
                              fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF8A00),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: TextStyle(
                        color: item.isRead ? Colors.white54 : Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMM d, h:mm a').format(item.createdAt),
                      style: const TextStyle(color: Colors.white30, fontSize: 12),
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
