import 'student_my_results_screen.dart';
import 'student_quiz_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz.dart';
import '../models/quiz_attempt.dart';
import '../providers/quiz_attempt_provider.dart';
import '../providers/quiz_provider.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends State<StudentNotificationsScreen> {
  static const _readKey = 'student_notification_read_ids';
  Set<String> _readIds = <String>{};
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _loadReadIds();
  }

  Future<void> _loadReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_readKey) ?? <String>[];
    if (!mounted) return;
    setState(() => _readIds = ids.toSet());
  }

  Future<void> _saveReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_readKey, _readIds.toList());
  }

  Future<void> _markAllRead(List<_StudentNotification> notifications) async {
    setState(() {
      _readIds.addAll(notifications.map((n) => n.id));
    });
    await _saveReadIds();
  }

  Future<void> _markRead(String id) async {
    if (_readIds.contains(id)) return;
    setState(() => _readIds.add(id));
    await _saveReadIds();
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_readKey);
    if (!mounted) return;
    setState(() => _readIds = <String>{});
  }

  List<_StudentNotification> _buildNotifications(
    List<Quiz> quizzes,
    List<QuizAttempt> attempts,
  ) {
    final notifications = <_StudentNotification>[];

    final sortedQuizzes = [...quizzes]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (final quiz in sortedQuizzes.take(10)) {
      notifications.add(
        _StudentNotification(
          id: 'quiz_${quiz.id}_${quiz.createdAt.millisecondsSinceEpoch}',
          title: 'New quiz available',
          body: quiz.title,
          time: quiz.createdAt,
          icon: Icons.quiz_outlined,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => StudentQuizDetailScreen(quizId: quiz.id))),
        ),
      );
    }

    final sortedAttempts = [...attempts]
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    for (final attempt in sortedAttempts.take(10)) {
      if (attempt.isSubmitted) {
        notifications.add(
          _StudentNotification(
            id: 'result_${attempt.id}',
            title: 'Quiz submitted',
            body:
                '${attempt.quizTitle}: ${attempt.score}/${attempt.totalMarks} (${attempt.grade})',
            time: attempt.endTime ?? attempt.startTime,
            icon: Icons.assignment_turned_in_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentMyResultsScreen())),
          ),
        );
      } else {
        notifications.add(
          _StudentNotification(
            id: 'progress_${attempt.id}',
            title: 'Attempt in progress',
            body: 'Resume ${attempt.quizTitle}',
            time: attempt.startTime,
            icon: Icons.play_circle_outline,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        StudentQuizDetailScreen(quizId: attempt.quizId))),
          ),
        );
      }
    }

    notifications.sort((a, b) => b.time.compareTo(a.time));
    return notifications.take(20).toList();
  }

  @override
  Widget build(BuildContext context) {
    final quizzes = context.watch<QuizProvider>().publishedQuizzes;
    final attempts = context.watch<QuizAttemptProvider>().studentAttempts;
    final allNotifications = _buildNotifications(quizzes, attempts);
    final items = _showUnreadOnly
        ? allNotifications.where((n) => !_readIds.contains(n.id)).toList()
        : allNotifications;
    final unreadCount =
        allNotifications.where((n) => !_readIds.contains(n.id)).length;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications${unreadCount > 0 ? ' ($unreadCount)' : ''}'),
        actions: [
          TextButton(
            onPressed: items.isEmpty ? null : () => _markAllRead(items),
            child: const Text('Mark all read'),
          ),
          IconButton(
            onPressed: _clearAll,
            tooltip: 'Clear read state',
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: !_showUnreadOnly,
                  onSelected: (_) => setState(() => _showUnreadOnly = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Unread'),
                  selected: _showUnreadOnly,
                  onSelected: (_) => setState(() => _showUnreadOnly = true),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none,
                            size: 56, color: colorScheme.outline),
                        const SizedBox(height: 8),
                        Text(
                          _showUnreadOnly
                              ? 'No unread notifications'
                              : 'No notifications yet',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: colorScheme.outlineVariant,
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isRead = _readIds.contains(item.id);
                      return ListTile(
                        onTap: () async {
                          await _markRead(item.id);
                          item.onTap();
                        },
                        leading: Icon(
                          item.icon,
                          color: isRead
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.primary,
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight:
                                isRead ? FontWeight.w500 : FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(item.body),
                        trailing: Text(
                          _timeAgo(item.time),
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}

class _StudentNotification {
  _StudentNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.onTap,
  });

  final String id;
  final String title;
  final String body;
  final DateTime time;
  final IconData icon;
  final VoidCallback onTap;
}
