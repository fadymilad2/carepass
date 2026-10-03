import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

part '../widgets/notifications/empty_state.dart';
part '../widgets/notifications/notification_tile.dart';

class NotificationsPage extends StatefulWidget {
  // [tl]
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _db = FirebaseFirestore.instance;
  User? _currentUser; // تخزين كائن المستخدم بالكامل
  String? get _uid => _currentUser?.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser; // تهيئة كائن المستخدم

    if (_uid != null) {
      Query<Map<String, dynamic>> baseQuery = _db
          .collection('users')
          .doc(_uid!) // استخدام _uid! بعد التأكد من أنه ليس null
          .collection('notifications')
          .orderBy('createdAt', descending: true);

      // تصفية الإشعارات لتظهر فقط تلك التي تم إنشاؤها بعد تسجيل المستخدم
      final userCreationTime = _currentUser?.metadata.creationTime;
      if (userCreationTime != null) {
        baseQuery = baseQuery.where(
          'createdAt',
          isGreaterThanOrEqualTo: userCreationTime.toIso8601String(),
        );
      }
      _stream = baseQuery.snapshots();

      // ✅ Mark all as read when page opens
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _markAllAsRead();
      });
    }
  }

  Future<void> _deleteNotification(String notifId) async {
    if (_uid == null) return;
    try {
      await _db
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .doc(notifId)
          .delete();
    } catch (_) {}
  }

  Future<void> _deleteAllNotifications() async {
    if (_uid == null) return;
    try {
      Query<Map<String, dynamic>> query = _db
          .collection('users')
          .doc(_uid!)
          .collection('notifications');

      // تطبيق نفس التصفية عند حذف جميع الإشعارات
      final userCreationTime = _currentUser?.metadata.creationTime;
      if (userCreationTime != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: userCreationTime.toIso8601String(),
        );
      }

      final snap = await query.get();

      if (snap.docs.isEmpty) return;

      for (var start = 0; start < snap.docs.length; start += 400) {
        final batch = _db.batch();
        for (final doc in snap.docs.skip(start).take(400)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    if (_uid == null) return;
    try {
      final snap = await _db
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      if (snap.docs.isEmpty) return;

      for (var start = 0; start < snap.docs.length; start += 400) {
        final batch = _db.batch();
        for (final doc in snap.docs.skip(start).take(400)) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (_) {}
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(dt);

      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d, y').format(dt);
    } catch (_) {
      return '';
    }
  }

  void _confirmDeleteAll() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Notifications?'),
        content: const Text(
          'This action will permanently delete all your notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAllNotifications();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_uid != null)
            TextButton.icon(
              onPressed: _confirmDeleteAll,
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: const Text('Clear All'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
            ),
        ],
      ),

      body: _uid == null
          ? _EmptyState(message: 'Sign in to view notifications')
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snap) {
                // ── Loading ──────────────────────────
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                // ── Error ────────────────────────────
                if (snap.hasError) {
                  return _EmptyState(
                    icon: Icons.error_outline,
                    message: 'Failed to load notifications',
                  );
                }

                final docs = snap.data?.docs ?? [];

                // ── Empty ────────────────────────────
                if (docs.isEmpty) {
                  return const _EmptyState();
                }

                // ── List ─────────────────────────────
                return ListView.separated(
                  padding: const EdgeInsets.all(AppDimens.paddingMD),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final data = docs[i].data();
                    final notifId = docs[i].id;
                    final isRead = data['isRead'] as bool? ?? false;

                    return Dismissible(
                      key: Key(notifId),
                      onDismissed: (_) => _deleteNotification(notifId),
                      background: Container(
                        color: AppColors.error.withValues(alpha: 0.8),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      secondaryBackground: Container(
                        color: AppColors.error.withValues(alpha: 0.8),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      child: _NotificationTile(
                        title: data['title'] as String? ?? '',
                        body: data['body'] as String? ?? '',
                        type: data['type'] as String? ?? 'general',
                        time: _timeAgo(data['createdAt'] as String?),
                        isRead: isRead,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────
//  Empty State
// ─────────────────────────────────────────────
