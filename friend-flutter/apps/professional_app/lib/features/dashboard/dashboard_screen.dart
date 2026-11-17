import 'package:flutter/material.dart';
import 'package:friend_professional/l10n/tr.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../auth/auth_controller.dart';
import '../clients/client_detail_screen.dart';
import '../shell/pro_stitch_chrome.dart';

final _dashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final now = DateTime.now().toUtc();
  final monthStart = DateTime(now.year, now.month, 1).toUtc();
  final results = await Future.wait([
    dio.get<Map<String, dynamic>>('/professional/appointments', queryParameters: {
      'starts_after': now.subtract(const Duration(hours: 2)).toIso8601String(),
      'ends_before': now.add(const Duration(days: 30)).toIso8601String(),
      'per_page': 50,
    }),
    dio.get<Map<String, dynamic>>('/professional/earnings/summary', queryParameters: {
      'days': 30,
    }),
    dio.get<Map<String, dynamic>>('/professionals/onboarding/status'),
    dio.get<Map<String, dynamic>>('/me/professional-profile'),
    dio.get<Map<String, dynamic>>('/professional/appointments', queryParameters: {
      'status': 'pending',
    }),
  ]);
  return {
    'appointments': (results[0].data?['data'] as List? ?? const []),
    'earnings_mtd': results[1].data ?? const {},
    'onboarding': results[2].data ?? const {},
    'profile': results[3].data?['data'] ?? results[3].data ?? const {},
    'pending': (results[4].data?['data'] as List? ?? const []),
    'month_start': monthStart.toIso8601String(),
  };
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleWalkIn(bool value) async {
    try {
      await ref.read(dioProvider).put('/me/professional-profile', data: {'offers_free_listening': value});
      ref.invalidate(_dashboardProvider);
      _toast(value ? tr('Walk-ins are on. Clients can request you now.') : tr('Walk-in paused.'));
    } catch (_) {
      _toast(tr("Couldn't update. Check your connection and try again."));
    }
  }

  Future<void> _respondListening(int id, bool accept) async {
    try {
      await ref.read(dioProvider).post('/appointments/$id/${accept ? 'accept' : 'decline'}');
      ref.invalidate(_dashboardProvider);
      if (!mounted) return;
      if (accept) {
        context.go('/sessions/$id/host');
      } else {
        _toast(tr('Request declined.'));
      }
    } catch (_) {
      _toast(tr("Couldn't update. Check your connection and try again."));
    }
  }

  void _openDossier(Map<String, dynamic> client, int sessionCount) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ClientDetailScreen(user: client, sessionCount: sessionCount)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_dashboardProvider);
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    final header = ProStitchCommandHeader(avatarInitial: user?.name, onAvatarTap: () => context.go('/profile'));

    return Column(
      children: [
        header,
        Expanded(
          child: async.when(
            loading: () => const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, __) => FriendEmptyState(
              icon: Icons.cloud_off_outlined,
              title: tr("Couldn't load your day"),
              message: tr('Check your connection and try again.'),
              ctaLabel: tr('Try again'),
              onCta: () => ref.invalidate(_dashboardProvider),
            ),
            data: (data) {
              final upcoming = (data['appointments'] as List).cast<Map<String, dynamic>>();
              final pendingAll = (data['pending'] as List).cast<Map<String, dynamic>>();
              final listeningRequests = pendingAll
                  .where((a) => a['kind'] == 'listening_request' && a['status'] == 'pending')
                  .toList();
              final earnings = data['earnings_mtd'] as Map<String, dynamic>;
              final onboarding = data['onboarding'] as Map<String, dynamic>;
              final profile = data['profile'] as Map<String, dynamic>;
              final offersWalkIn = profile['offers_free_listening'] == true;
              final firstName = _shortName(user?.name ?? '');
              final queue = _consultationQueue(upcoming);
              final rating = (profile['rating_avg'] as num?)?.toDouble() ?? 0;
              final ratingCount = (profile['rating_count'] as num?)?.toInt() ?? 0;

              return RefreshIndicator(
                color: FriendColors.primary,
                backgroundColor: FriendColors.surface,
                onRefresh: () async => ref.invalidate(_dashboardProvider),
                child: FriendContentWidth(
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 20, FriendLayout.horizontal, 32),
                    children: [
                      Text(trDate('EEEE, d MMMM', DateTime.now()), style: theme.textTheme.labelMedium?.copyWith(color: FriendColors.textMuted)),
                      const SizedBox(height: 4),
                      Semantics(
                        header: true,
                        child: Text(
                          firstName.isEmpty ? _greeting() : '${_greeting()}, $firstName',
                          style: theme.textTheme.headlineLarge,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _StatsCard(
                        today: _sessionsToday(upcoming),
                        earned: _formatMtd(earnings),
                        rating: ratingCount > 0 ? rating.toStringAsFixed(1) : '—',
                        onEarnings: () => context.go('/earnings'),
                      ),
                      const SizedBox(height: 12),
                      _WalkInCard(enabled: offersWalkIn, onChanged: _toggleWalkIn),
                      if (listeningRequests.isNotEmpty) ...[
                        const SizedBox(height: FriendLayout.sectionGap),
                        _ListeningSection(
                          requests: listeningRequests,
                          onAccept: (id) => _respondListening(id, true),
                          onDecline: (id) => _respondListening(id, false),
                        ),
                      ],
                      const SizedBox(height: FriendLayout.sectionGap),
                      _QueueSection(
                        queue: queue,
                        onLaunchMeet: (id) => context.go('/sessions/$id/host'),
                        onDossier: _openDossier,
                        onAll: () => context.go('/sessions'),
                      ),
                      _OnboardingNudge(onboarding: onboarding),
                      const SizedBox(height: FriendLayout.sectionGap),
                      FriendSectionLabel(tr('Shortcuts')),
                      FriendListGroup(
                        children: [
                          FriendMenuTile(icon: Icons.sensors_rounded, title: tr('Go live'), subtitle: tr('Broadcast a reflection or cook-along'), onTap: () => context.push('/live')),
                          FriendMenuTile(icon: Icons.calendar_month_outlined, title: tr('Weekly hours'), subtitle: tr('When clients can book you'), onTap: () => context.go('/availability')),
                          FriendMenuTile(icon: Icons.people_outline_rounded, title: tr('Clients'), onTap: () => context.go('/clients')),
                          FriendMenuTile(icon: Icons.payments_outlined, title: tr('Earnings'), onTap: () => context.go('/earnings')),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// "Dr. Hanna Tesfaye" → "Dr. Hanna"; "Selam Bekele" → "Selam".
String _shortName(String full) {
  final parts = full.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  const titles = {'dr', 'dr.', 'abba', 'aba', 'chef', 'w/ro', 'ato', 'pastor', 'sheikh', 'prof', 'prof.'};
  if (parts.length > 1 && titles.contains(parts.first.toLowerCase())) return '${parts[0]} ${parts[1]}';
  return parts.first;
}

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return tr('Good morning');
  if (h < 17) return tr('Good afternoon');
  return tr('Good evening');
}

int _sessionsToday(List<Map<String, dynamic>> appts) {
  final now = DateTime.now();
  return appts.where((a) {
    if (a['status'] == 'cancelled') return false;
    final when = DateTime.tryParse(a['scheduled_at'] as String? ?? '')?.toLocal();
    return when != null && DateUtils.isSameDay(when, now);
  }).length;
}

List<Map<String, dynamic>> _consultationQueue(List<Map<String, dynamic>> appts) {
  final cutoff = DateTime.now().subtract(const Duration(minutes: 30));
  final list = appts.where((a) {
    if (a['status'] == 'cancelled') return false;
    final when = DateTime.tryParse(a['scheduled_at'] as String? ?? '');
    return when != null && !when.isBefore(cutoff);
  }).toList()
    ..sort((a, b) => DateTime.parse(a['scheduled_at'] as String).compareTo(DateTime.parse(b['scheduled_at'] as String)));
  return list;
}

String _formatMtd(Map<String, dynamic> earnings) {
  final major = (earnings['total_cents'] as num? ?? 0) / 100;
  return major >= 10000 ? '${(major / 1000).toStringAsFixed(1)}k' : major.toStringAsFixed(0);
}

String _formatLabel(Map<String, dynamic> appt) {
  if (appt['recipe'] is Map) return trx('Cooking · ${(appt['recipe'] as Map)['title']}', 'ምግብ ዝግጅት · ${(appt['recipe'] as Map)['title']}');
  if (appt['kind'] == 'listening_request') return tr('Walk-in');
  return switch (appt['care_format'] as String? ?? 'individual') {
    'couples' => tr('Couples session'),
    'family' => tr('Family session'),
    'child' => tr('Child session'),
    'teen' => tr('Teen session'),
    _ => tr('One-to-one session'),
  };
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.today, required this.earned, required this.rating, required this.onEarnings});

  final int today;
  final String earned;
  final String rating;
  final VoidCallback onEarnings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget cell(String value, String label, {VoidCallback? onTap}) => Expanded(
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  Text(value, style: theme.textTheme.titleLarge?.copyWith(fontFeatures: friendTabular)),
                  const SizedBox(height: 2),
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall),
                ],
              ),
            ),
          ),
        );
    return CandyCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            cell('$today', tr('Sessions today')),
            const VerticalDivider(width: 1),
            cell(earned, tr('ETB earned, 30 days'), onTap: onEarnings),
            const VerticalDivider(width: 1),
            cell(rating, tr('Rating')),
          ],
        ),
      ),
    );
  }
}

class _WalkInCard extends StatelessWidget {
  const _WalkInCard({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CandyCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          Icon(Icons.hearing_rounded, color: enabled ? FriendColors.success : FriendColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Available for walk-ins'), style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  enabled ? tr('Clients can ask you for a free listening session now.') : tr('Turn on to take free listening requests.'),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _QueueSection extends StatelessWidget {
  const _QueueSection({required this.queue, required this.onLaunchMeet, required this.onDossier, required this.onAll});

  final List<Map<String, dynamic>> queue;
  final void Function(String id) onLaunchMeet;
  final void Function(Map<String, dynamic> client, int count) onDossier;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FriendSectionLabel(tr('Up next'), action: queue.length > 1 ? tr('All sessions') : null, onAction: onAll),
        if (queue.isEmpty)
          CandyCard(
            child: Row(
              children: [
                const Icon(Icons.event_available_outlined, color: FriendColors.textMuted),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('No upcoming consultations'), style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(tr('Bookings from clients will appear here.'), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          )
        else ...[
          _ActiveQueueCard(appt: queue.first, onLaunchMeet: onLaunchMeet, onDossier: onDossier),
          if (queue.length > 1) ...[
            const SizedBox(height: 12),
            FriendListGroup(
              dividerIndent: 68,
              children: [for (final a in queue.skip(1).take(4)) _CompactQueueRow(appt: a, onDossier: onDossier)],
            ),
          ],
        ],
      ],
    );
  }
}

class _ActiveQueueCard extends StatelessWidget {
  const _ActiveQueueCard({required this.appt, required this.onLaunchMeet, required this.onDossier});

  final Map<String, dynamic> appt;
  final void Function(String id) onLaunchMeet;
  final void Function(Map<String, dynamic> client, int count) onDossier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startsAt = DateTime.parse(appt['scheduled_at'] as String).toLocal();
    final guest = (appt['client'] as Map<String, dynamic>?) ?? const {};
    final name = guest['name'] as String? ?? tr('Client');
    final id = '${appt['id']}';
    final duration = (appt['duration_minutes'] as num?)?.toInt() ?? 50;
    final mins = startsAt.difference(DateTime.now()).inMinutes;
    final soon = mins <= 15;
    final startsLabel = mins <= 0
        ? tr('Now')
        : mins < 60
            ? trx('In $mins min', 'በ$mins ደቂቃ ውስጥ')
            : mins < 24 * 60
                ? trx('In ${mins ~/ 60}h ${mins % 60}m', 'በ${mins ~/ 60} ሰዓት ${mins % 60} ደቂቃ ውስጥ')
                : trDate('EEE d MMM', startsAt);
    final note = (appt['client_note'] as String?)?.trim();

    return CandyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              FriendAvatar(size: 44, initials: personInitial(name)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatLabel(appt)} · ${trDate('h:mm a', startsAt)} · ${trx('$duration min', '$duration ደቂቃ')}',
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (soon) const FriendLivePulse(size: 7),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            startsLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: soon ? FriendColors.live : FriendColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: FriendColors.recessed, borderRadius: BorderRadius.circular(FriendRadii.medium)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Client note'), style: theme.textTheme.labelSmall),
                  const SizedBox(height: 2),
                  Text(note, style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textPrimary), maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FriendGlowButton(label: tr('Client record'), secondary: true, expanded: true, onPressed: () => onDossier(guest, 1)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FriendGlowButton(
                  label: tr('Start'),
                  icon: Icons.videocam_rounded,
                  expanded: true,
                  onPressed: () => onLaunchMeet(id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactQueueRow extends StatelessWidget {
  const _CompactQueueRow({required this.appt, required this.onDossier});

  final Map<String, dynamic> appt;
  final void Function(Map<String, dynamic> client, int count) onDossier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startsAt = DateTime.parse(appt['scheduled_at'] as String).toLocal();
    final guest = (appt['client'] as Map<String, dynamic>?) ?? const {};
    final name = guest['name'] as String? ?? tr('Client');
    return InkWell(
      onTap: () => onDossier(guest, 1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            FriendAvatar(size: 36, initials: personInitial(name)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(_formatLabel(appt), style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Text(
              DateUtils.isSameDay(startsAt, DateTime.now()) ? trDate('h:mm a', startsAt) : trDate('EEE h:mm a', startsAt),
              style: theme.textTheme.labelMedium?.copyWith(fontFeatures: friendTabular),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListeningSection extends StatelessWidget {
  const _ListeningSection({required this.requests, required this.onAccept, required this.onDecline});

  final List<Map<String, dynamic>> requests;
  final void Function(int id) onAccept;
  final void Function(int id) onDecline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FriendSectionLabel(tr('Walk-in requests')),
        for (final a in requests)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CandyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const FriendLivePulse(size: 6, color: FriendColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text((a['client'] as Map?)?['name'] as String? ?? tr('Client'), style: theme.textTheme.titleSmall),
                      ),
                    ],
                  ),
                  if ((a['client_note'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(a['client_note'] as String, style: theme.textTheme.bodySmall),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FriendGlowButton(
                          label: tr('Decline'),
                          secondary: true,
                          expanded: true,
                          onPressed: () => onDecline((a['id'] as num).toInt()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FriendGlowButton(label: tr('Accept & join'), expanded: true, onPressed: () => onAccept((a['id'] as num).toInt())),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _OnboardingNudge extends StatelessWidget {
  const _OnboardingNudge({required this.onboarding});
  final Map<String, dynamic> onboarding;

  @override
  Widget build(BuildContext context) {
    final pending = (onboarding['pending_steps'] as List? ?? const []).map((e) => tr('$e')).toList();
    if (pending.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: CandyCard(
        tint: FriendColors.warning,
        onTap: () => context.go('/onboarding'),
        child: Row(
          children: [
            const Icon(Icons.checklist_rounded, color: FriendColors.warning),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Finish setting up your practice'), style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(trx('Still to do: ${pending.join(", ")}', 'የሚቀሩ፦ ${pending.join("፣ ")}'), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: FriendColors.textMuted),
          ],
        ),
      ),
    );
  }
}
