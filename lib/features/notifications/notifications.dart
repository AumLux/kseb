import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design/design.dart';
import '../../core/errors/app_failure.dart';
import '../../core/format/formatters.dart';
import '../../core/l10n/l10n.dart';
import '../../core/supabase/providers.dart';
import '../auth/application/session_controller.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.createdAt,
    this.body,
    this.route,
    this.readAt,
  });

  final String id;
  final String title;
  final String? body;
  final String? route;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get unread => readAt == null;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String?,
        route: j['route'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
        readAt: j['read_at'] == null ? null : DateTime.parse(j['read_at'] as String).toLocal(),
      );
}

final FutureProvider<List<AppNotification>> notificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  // Keep the realtime subscription alive while anything shows notifications.
  ref.watch(_notificationsLiveProvider);
  try {
    final rows = await ref
        .watch(supabaseClientProvider)
        .from('notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(100);
    return rows.map(AppNotification.fromJson).toList();
  } catch (e) {
    throw AppFailure.from(e);
  }
});

final unreadCountProvider = Provider.autoDispose<int>(
    (ref) => ref.watch(notificationsProvider).value?.where((n) => n.unread).length ?? 0);

/// Realtime: new notifications for me refresh the inbox and badge.
final Provider<void> _notificationsLiveProvider = Provider.autoDispose<void>((ref) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return;
  final client = ref.watch(supabaseClientProvider);
  final channel = client
      .channel('notifications-${me.id}')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: me.id),
        callback: (_) => ref.invalidate(notificationsProvider),
      )
      .subscribe();
  ref.onDispose(() => unawaited(client.removeChannel(channel)));
});

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref, AppNotification n) async {
    final client = ref.read(supabaseClientProvider);
    if (n.unread) {
      try {
        await client.from('notifications').update({'read_at': DateTime.now().toUtc().toIso8601String()}).eq('id', n.id);
      } catch (_) {}
      ref.invalidate(notificationsProvider);
    }
    if (n.route != null && context.mounted) context.push(n.route!);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifTitle),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () async {
                await ref.read(supabaseClientProvider).rpc('mark_all_notifications_read');
                ref.invalidate(notificationsProvider);
              },
              child: Text(l10n.notifMarkAll),
            ),
        ],
      ),
      body: switch (list) {
        AsyncData(:final value) when value.isEmpty =>
          EmptyState(icon: Icons.notifications_none_rounded, title: l10n.notifEmpty),
        AsyncData(:final value) => RefreshIndicator(
            onRefresh: () => ref.refresh(notificationsProvider.future),
            child: ListView(children: [
              for (final n in value)
                AppListRow(
                  selected: n.unread,
                  leading: Icon(
                    n.unread ? Icons.circle : Icons.circle_outlined,
                    size: 10,
                    color: n.unread ? AppColors.primaryInk : AppColors.inkDisabled,
                  ),
                  title: n.title,
                  subtitle: [?n.body, Fmt.dateTime(n.createdAt)].join('\n'),
                  onTap: () => _open(context, ref, n),
                ),
            ]),
          ),
        AsyncError(:final error) => ErrorState(
            title: l10n.commonSomethingWrong,
            message: failureMessage(l10n, error),
            onRetry: () => ref.invalidate(notificationsProvider),
          ),
        _ => const LoadingView(),
      },
    );
  }
}

/// App-bar bell with the unread count.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadCountProvider);
    return IconButton(
      tooltip: context.l10n.notifTitle,
      onPressed: () => context.push('/home/notifications'),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        backgroundColor: AppColors.danger,
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
