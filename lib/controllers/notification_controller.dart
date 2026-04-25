import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationController extends ChangeNotifier {
  final NotificationService _service;
  final SupabaseClient _supabase;

  List<NotificationItem> _notifications = [];
  NotificationPreferences? _preferences;
  bool _isLoading = false;
  RealtimeChannel? _subscription;

  NotificationController(this._supabase) : _service = NotificationService(_supabase);

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  NotificationPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadNotifications(),
        _loadPreferences(),
      ]);
      _setupRealtimeSubscription();
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadNotifications() async {
    _notifications = await _service.getNotifications();
  }

  Future<void> _loadPreferences() async {
    _preferences = await _service.getPreferences();
  }

  void _setupRealtimeSubscription() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _subscription = _supabase
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _loadNotifications().then((_) => notifyListeners());
          },
        )
        .subscribe();
  }

  Future<void> markAsRead(int id) async {
    try {
      await _service.markAsRead(id);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        final n = _notifications[index];
        _notifications[index] = NotificationItem(
          id: n.id,
          title: n.title,
          message: n.message,
          type: n.type,
          priority: n.priority,
          isRead: true,
          createdAt: n.createdAt,
          redirectRoute: n.redirectRoute,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      _notifications = _notifications.map((n) {
        return NotificationItem(
          id: n.id,
          title: n.title,
          message: n.message,
          type: n.type,
          priority: n.priority,
          isRead: true,
          createdAt: n.createdAt,
          redirectRoute: n.redirectRoute,
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(int id) async {
    try {
      await _service.deleteNotification(id);
      _notifications.removeWhere((n) => n.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> updatePreferences(Map<String, dynamic> updates) async {
    try {
      await _service.updatePreferences(updates);
      await _loadPreferences();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating preferences: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}
