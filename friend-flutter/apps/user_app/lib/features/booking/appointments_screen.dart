import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

    return FriendTabScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FriendPageHeader(
            eyebrow: 'Sessions',
            title: 'Your sessions',
            subtitle: 'Everything you have booked, in one place.',
          ),
          Expanded(
            child: apptsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) => FriendEmptyState(
                icon: Icons.cloud_off_outlined,
                title: "Couldn't load sessions",
                message: 'Pull to refresh or try again shortly.',
              ),
              data: (list) {
                if (list.isEmpty) {
                  return FriendEmptyState(
                    icon: Icons.videocam_off_outlined,
                    title: 'No sessions yet',
                    message: 'Discover someone who feels right.',
                    ctaLabel: 'Discover listeners',
                    onCta: () => context.go('/'),
                  );
                }

                final now = DateTime.now();
                final sorted = [...list]..sort((a, b) {
                    final aWhen = DateTime.tryParse(a['scheduled_at'] as String? ?? '');
                    final bWhen = DateTime.tryParse(b['scheduled_at'] as String? ?? '');
                    if (aWhen == null || bWhen == null) return 0;
                    return aWhen.compareTo(bWhen);
                  });
                final nextUp = sorted.cast<Map<String, dynamic>?>().firstWhere(
                      (a) {
                        if (a == null) return false;
                        if (a['status'] == 'cancelled') return false;
                        final when = DateTime.tryParse(a['scheduled_at'] as String? ?? '');
                        return when != null && !when.isBefore(now);
                      },
                      orElse: () => null,
                    );

                final rest = nextUp == null
                    ? sorted
                    : sorted
                        .where((a) => a['id'] != nextUp['id'])
                        .toList();

                return RefreshIndicator(
                  color: FriendColors.accent,
                  onRefresh: () async => ref.invalidate(_appointmentsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      FriendLayout.horizontal,
                      0,
                      FriendLayout.horizontal,
                      FriendLayout.horizontal,
                    ),
                    itemCount: rest.length + (nextUp != null ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      if (nextUp != null && i == 0) {
                        return _NextUpHero(appt: nextUp);
                      }
                      final index = nextUp != null ? i - 1 : i;
                      return _AppointmentCard(appt: rest[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NextUpHero extends StatelessWidget {
  const _NextUpHero({required this.appt});
  final Map<String, dynamic> appt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduledAt = DateTime.parse(appt['scheduled_at'] as String).toLocal();
    final pro = appt['professional'] as Map<String, dynamic>?;
    final proName = pro?['name'] ?? 'Listener';
    final status = appt['status'] as String? ?? 'pending';
    final duration = (appt['duration_minutes'] as num?)?.toInt() ?? 45;
    final minsUntil = scheduledAt.difference(DateTime.now()).inMinutes;
    final priceCents = (appt['price_cents'] as num?)?.toInt() ?? -1;
    final kind = appt['kind'] as String? ?? 'scheduled';
    final waitingAccept =
        kind == 'listening_request' && status == 'pending';
    final canJoin = !waitingAccept &&
        (status == 'pending' ||
            status == 'confirmed' ||
            status == 'in_progress') &&
        (priceCents == 0 ||
            (minsUntil <= 15 && minsUntil >= -(duration + 30)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FriendSectionLabel('Next up'),
        FriendHeroCard(
          tint: FriendColors.primary,
          onTap: canJoin
              ? () => context.go('/appointments/${appt['id']}/room')
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(proName, style: theme.textTheme.headlineSmall),
                  ),
                  FriendStatusChip(
                    label: waitingAccept
                        ? 'Awaiting listener'
                        : status == 'confirmed'
                            ? 'Confirmed'
                            : 'Pending',
                    color: waitingAccept
                        ? FriendColors.accent
                        : status == 'confirmed'
                            ? FriendColors.primary
                            : FriendColors.accent,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('EEEE, MMM d · h:mm a').format(scheduledAt),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: FriendColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FriendGlowButton(
                      label: canJoin ? 'Join session' : 'Open waiting room',
                      icon: Icons.videocam_rounded,
                      expanded: true,
                      onPressed: () =>
                          context.go('/appointments/${appt['id']}/room'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.go('/appointments/${appt['id']}/room'),
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('Setup'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FriendColors.primary,
                      side: const BorderSide(color: FriendColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FriendRadii.pill),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const FriendSectionLabel('All sessions'),
      ],
    );
  }
}

class _AppointmentCard extends ConsumerWidget {
  const _AppointmentCard({required this.appt});
  final Map<String, dynamic> appt;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this session?'),
        content: const Text('Refund policy may apply.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel session'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final dio = ref.read(dioProvider);
    await dio.put('/appointments/${appt['id']}/cancel');
    ref.invalidate(_appointmentsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduledAt = DateTime.parse(appt['scheduled_at'] as String).toLocal();
    final status = appt['status'] as String? ?? 'pending';
    final pro = appt['professional'] as Map<String, dynamic>?;
    final proName = pro?['name'] ?? 'Listener';
    final minsUntil = scheduledAt.difference(DateTime.now()).inMinutes;
    final duration = (appt['duration_minutes'] as num?)?.toInt() ?? 45;
    final priceCents = (appt['price_cents'] as num?)?.toInt() ?? -1;
    final kind = appt['kind'] as String? ?? 'scheduled';
    final waitingAccept =
        kind == 'listening_request' && status == 'pending';
    final canJoin = !waitingAccept &&
        (status == 'pending' ||
            status == 'confirmed' ||
            status == 'in_progress') &&
        (priceCents == 0 ||
            (minsUntil <= 15 && minsUntil >= -(duration + 30)));

    return CandyCard(
      accentStripe: true,
      tint: canJoin ? FriendColors.primary : FriendColors.aqua,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  proName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _StatusBadge(
                status: waitingAccept ? 'awaiting' : status,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('EEE, MMM d · h:mm a').format(scheduledAt),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: FriendColors.textSecondary,
                ),
          ),
          if (_careLine(appt) case final line?) ...[
            const SizedBox(height: 4),
            Text(line, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: FriendColors.textMuted)),
          ],
          if (appt['recipe'] is Map && (status == 'pending' || status == 'confirmed')) ...[
            const SizedBox(height: 10),
            _RecipeNudge(appt: appt),
          ],
          if (status == 'pending' || status == 'confirmed' || canJoin || waitingAccept) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              if (canJoin)
                FriendGlowButton(
                  label: 'Join session',
                  icon: Icons.videocam_rounded,
                  onPressed: () =>
                      context.go('/appointments/${appt['id']}/room'),
                )
              else if (waitingAccept)
                Text(
                  'Awaiting listener',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: FriendColors.textMuted,
                      ),
                )
              else if (status == 'pending' || status == 'confirmed')
                Text(
                  minsUntil > 15
                      ? 'Opens 15 min before'
                      : 'Join window closed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: FriendColors.textMuted,
                      ),
                ),
              const Spacer(),
              if (status == 'pending' || status == 'confirmed')
                TextButton(
                  onPressed: () => _cancel(context, ref),
                  child: const Text('Cancel'),
                ),
            ],
          ),
          ],
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
    'couples' => 'Couples session',
    'family' => 'Family session',
    'child' || 'teen' => 'For ${dependent?['name'] ?? 'your child'}',
    _ => null,
  };
  if (label == null) return null;
  return others.isEmpty ? label : '$label · with $others';
}

/// Cooking sessions: get the ingredients, then confirm.
class _RecipeNudge extends StatelessWidget {
  const _RecipeNudge({required this.appt});
  final Map<String, dynamic> appt;

  @override
  Widget build(BuildContext context) {
    final recipe = appt['recipe'] as Map;
    final ready = appt['ingredients_confirmed_at'] != null;
    return Material(
      color: ready ? FriendColors.primaryLight : FriendColors.woodLight,
      borderRadius: BorderRadius.circular(FriendRadii.medium),
      child: InkWell(
        borderRadius: BorderRadius.circular(FriendRadii.medium),
        onTap: () => context.push('/recipes/${recipe['id']}?appointment=${appt['id']}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                ready ? Icons.check_circle_rounded : Icons.shopping_basket_outlined,
                size: 18,
                color: ready ? FriendColors.primary : FriendColors.woodDeep,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ready ? 'Ingredients ready · ${recipe['title']}' : 'Get your ingredients · ${recipe['title']}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18),
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
      'confirmed' => (FriendColors.primary, 'Confirmed'),
      'pending' => (FriendColors.accent, 'Pending'),
      'awaiting' => (FriendColors.accent, 'Awaiting listener'),
      'cancelled' => (FriendColors.error, 'Cancelled'),
      'completed' => (FriendColors.textSecondary, 'Done'),
      _ => (FriendColors.textSecondary, status),
    };
    return FriendStatusChip(label: label, color: color);
  }
}
