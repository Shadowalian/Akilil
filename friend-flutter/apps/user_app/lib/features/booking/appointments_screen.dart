import 'package:friend_user/l10n/tr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

final _appointmentsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/appointments');
  return ((res.data?['data'] as List?) ?? const [])
      .cast<Map<String, dynamic>>();
});

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apptsAsync = ref.watch(_appointmentsProvider);

    Widget scroll(List<Widget> children) => RefreshIndicator(
          color: FriendColors.primary,
          backgroundColor: FriendColors.surface,
          onRefresh: () async => ref.invalidate(_appointmentsProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const SizedBox(height: 16),
              FriendPageHeader(
                eyebrow: '',
                title: tr('Your sessions'),
                subtitle: tr('Everything you have booked, in one place.'),
              ),
              ...children,
            ],
          ),
        );

    return FriendTabScaffold(
      body: apptsAsync.when(
        loading: () => scroll(const [
          Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
          ),
        ]),
        error: (e, _) => scroll([
          FriendEmptyState(
            icon: Icons.cloud_off_outlined,
            title: tr("Couldn't load sessions"),
            message: tr('Pull to refresh or try again shortly.'),
            ctaLabel: tr('Try again'),
            onCta: () => ref.invalidate(_appointmentsProvider),
          ),
        ]),
        data: (list) {
          if (list.isEmpty) {
            return scroll([
              FriendEmptyState(
                icon: Icons.event_available_outlined,
                title: tr('No sessions yet'),
                message: tr('Discover someone who feels right.'),
                ctaLabel: tr('Find someone'),
                onCta: () => context.go('/'),
              ),
            ]);
          }

          final now = DateTime.now();
          DateTime whenOf(Map<String, dynamic> a) =>
              DateTime.tryParse(a['scheduled_at'] as String? ?? '')?.toLocal() ?? now;
          bool isUpcoming(Map<String, dynamic> a) {
            final status = a['status'] as String? ?? '';
            if (status == 'cancelled' || status == 'completed') return false;
            final duration = (a['duration_minutes'] as num?)?.toInt() ?? 45;
            return whenOf(a).add(Duration(minutes: duration + 30)).isAfter(now);
          }

          final upcoming = list.where(isUpcoming).toList()..sort((a, b) => whenOf(a).compareTo(whenOf(b)));
          final past = list.where((a) => !isUpcoming(a)).toList()..sort((a, b) => whenOf(b).compareTo(whenOf(a)));

          return scroll([
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: FriendLayout.horizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FriendSectionLabel(tr('Upcoming')),
                  if (upcoming.isEmpty)
                    CandyCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              tr('Nothing booked. When you book a session it shows up here.'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          TextButton(onPressed: () => context.go('/'), child: Text(tr('Find someone'))),
                        ],
                      ),
                    )
                  else
                    for (var i = 0; i < upcoming.length; i++) ...[
                      _UpcomingCard(appt: upcoming[i], featured: i == 0),
                      const SizedBox(height: 12),
                    ],
                  if (past.isNotEmpty) ...[
                    const SizedBox(height: FriendLayout.sectionGap - 12),
                    FriendSectionLabel(tr('Past')),
                    FriendListGroup(
                      dividerIndent: 16,
                      children: [for (final a in past) _PastRow(appt: a)],
                    ),
                  ],
                ],
              ),
            ),
          ]);
        },
      ),
    );
  }
}

bool _canJoin(Map<String, dynamic> appt) {
  final scheduledAt = DateTime.parse(appt['scheduled_at'] as String).toLocal();
  final status = appt['status'] as String? ?? 'pending';
  final duration = (appt['duration_minutes'] as num?)?.toInt() ?? 45;
  final minsUntil = scheduledAt.difference(DateTime.now()).inMinutes;
  final priceCents = (appt['price_cents'] as num?)?.toInt() ?? -1;
  final waiting = appt['kind'] == 'listening_request' && status == 'pending';
  return !waiting &&
      (status == 'pending' || status == 'confirmed' || status == 'in_progress') &&
      (priceCents == 0 || (minsUntil <= 15 && minsUntil >= -(duration + 30)));
}

class _UpcomingCard extends ConsumerWidget {
  const _UpcomingCard({required this.appt, required this.featured});

  final Map<String, dynamic> appt;
  final bool featured;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('Cancel this session?')),
        content: Text(tr('Refund policy may apply.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(tr('Keep'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: FriendColors.error, minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr('Cancel session')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(dioProvider).put('/appointments/${appt['id']}/cancel');
      ref.invalidate(_appointmentsProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr("Couldn't cancel. Check your connection and try again."))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheduledAt = DateTime.parse(appt['scheduled_at'] as String).toLocal();
    final status = appt['status'] as String? ?? 'pending';
    final pro = appt['professional'] as Map<String, dynamic>?;
    final proName = '${pro?['name'] ?? tr('Listener')}';
    final duration = (appt['duration_minutes'] as num?)?.toInt() ?? 45;
    final minsUntil = scheduledAt.difference(DateTime.now()).inMinutes;
    final waitingAccept = appt['kind'] == 'listening_request' && status == 'pending';
    final canJoin = _canJoin(appt);
    final end = scheduledAt.add(Duration(minutes: duration));
    final id = appt['id'];

    return CandyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateBadge(date: scheduledAt),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(proName, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${trDate('h:mm', scheduledAt)}–${trDate('h:mm a', end)}',
                      style: theme.textTheme.bodySmall?.copyWith(fontFeatures: friendTabular),
                    ),
                    if (_careLine(appt) case final line?) ...[
                      const SizedBox(height: 2),
                      Text(line, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              _StatusBadge(status: waitingAccept ? 'awaiting' : status),
            ],
          ),
          if (appt['recipe'] is Map) ...[
            const SizedBox(height: 12),
            _RecipeNudge(appt: appt),
          ],
          const SizedBox(height: 14),
          if (featured || canJoin)
            Row(
              children: [
                Expanded(
                  child: FriendGlowButton(
                    label: tr('Check camera'),
                    secondary: true,
                    expanded: true,
                    onPressed: () => context.go('/appointments/$id/setup'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FriendGlowButton(
                    label: canJoin ? tr('Join session') : tr('Waiting room'),
                    icon: canJoin ? Icons.videocam_rounded : null,
                    expanded: true,
                    onPressed: waitingAccept ? null : () => context.go('/appointments/$id/room'),
                  ),
                ),
              ],
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  waitingAccept
                      ? tr('Waiting for the listener to accept.')
                      : canJoin
                          ? tr('You can join now.')
                          : minsUntil > 15
                              ? tr('Opens 15 min before')
                              : tr('Join window closed'),
                  style: theme.textTheme.labelSmall,
                ),
              ),
              if (status == 'pending' || status == 'confirmed')
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: FriendColors.error),
                  onPressed: () => _cancel(context, ref),
                  child: Text(tr('Cancel')),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Day-of-month badge on session cards.
class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(color: FriendColors.recessed, borderRadius: BorderRadius.circular(FriendRadii.medium)),
      child: Column(
        children: [
          Text(trDate('MMM', date), style: theme.textTheme.labelSmall),
          Text('${date.day}', style: theme.textTheme.titleLarge?.copyWith(height: 1.1, fontFeatures: friendTabular)),
          Text(trDate('EEE', date), style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _PastRow extends StatelessWidget {
  const _PastRow({required this.appt});

  final Map<String, dynamic> appt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduledAt = DateTime.parse(appt['scheduled_at'] as String).toLocal();
    final status = appt['status'] as String? ?? 'completed';
    final pro = appt['professional'] as Map<String, dynamic>?;
    final proName = '${pro?['name'] ?? tr('Listener')}';
    final proProfileId = pro?['profile_id'] ?? pro?['professional_profile_id'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(proName, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  [trDate('EEE d MMM · h:mm a', scheduledAt), if (status == 'cancelled') tr('Cancelled')].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (proProfileId != null)
            TextButton(onPressed: () => context.go('/pros/$proProfileId'), child: Text(tr('Book again'))),
        ],
      ),
    );
  }
}

/// "Couples session · with Dawit" / "For Abel" — who a session is for.
String? _careLine(Map<String, dynamic> appt) {
  final format = appt['care_format'] as String? ?? 'individual';
  final dependent = appt['dependent'] as Map?;
  final others = ((appt['participants'] as List?) ?? const []).map((p) => (p as Map)['name']).join(', ');
  final label = switch (format) {
    'couples' => tr('Couples session'),
    'family' => tr('Family session'),
    'child' || 'teen' => trx('For ${dependent?['name'] ?? 'your child'}', 'ለ${dependent?['name'] ?? 'ልጅዎ'}'),
    _ => null,
  };
  if (label == null) return null;
  return others.isEmpty ? label : trx('$label · with $others', '$label · ከ$others ጋር');
}

/// Cooking sessions: get the ingredients, then confirm.
class _RecipeNudge extends StatelessWidget {
  const _RecipeNudge({required this.appt});
  final Map<String, dynamic> appt;

  @override
  Widget build(BuildContext context) {
    final recipe = appt['recipe'] as Map;
    final ready = appt['ingredients_confirmed_at'] != null;
    final color = ready ? FriendColors.success : FriendColors.pillarCooking;
    return Material(
      color: Color.alphaBlend(color.withValues(alpha: 0.08), FriendColors.surface),
      borderRadius: BorderRadius.circular(FriendRadii.medium),
      child: InkWell(
        borderRadius: BorderRadius.circular(FriendRadii.medium),
        onTap: () => context.push('/recipes/${recipe['id']}?appointment=${appt['id']}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(ready ? Icons.check_circle_rounded : Icons.shopping_basket_outlined, size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ready
                      ? trx('Ingredients ready · ${recipe['title']}', 'ግብዓቶቹ ተዘጋጅተዋል · ${recipe['title']}')
                      : trx('Get your ingredients · ${recipe['title']}', 'ግብዓቶቹን ያዘጋጁ · ${recipe['title']}'),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: FriendColors.textPrimary),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: FriendColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'confirmed' => (FriendColors.success, tr('Confirmed')),
      'pending' => (FriendColors.warning, tr('Pending')),
      'awaiting' => (FriendColors.warning, tr('Awaiting listener')),
      'in_progress' => (FriendColors.live, tr('In progress')),
      'cancelled' => (FriendColors.error, tr('Cancelled')),
      'completed' => (FriendColors.textSecondary, tr('Done')),
      _ => (FriendColors.textSecondary, status),
    };
    return FriendStatusChip(label: label, color: color);
  }
}
