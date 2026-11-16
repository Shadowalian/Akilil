import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
  final List<String> _eveningSlots = ['7:15 PM', '8:30 PM (Standby)'];

  Future<void> _toggleWalkIn(bool value) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.put('/me/professional-profile', data: {
        'offers_free_listening': value,
      });
      ref.invalidate(_dashboardProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Online walk-in activated.' : 'Walk-in paused.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update: $e')),
      );
    }
  }

  Future<void> _respondListening(int id, bool accept) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/appointments/$id/${accept ? 'accept' : 'decline'}');
      ref.invalidate(_dashboardProvider);
      if (!mounted) return;
      if (accept) {
        context.go('/sessions/$id/host');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request declined.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  void _openDossier(Map<String, dynamic> client, int sessionCount) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ClientDetailScreen(
          user: client,
          sessionCount: sessionCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_dashboardProvider);
    final user = ref.watch(currentUserProvider);
    final headerInset = MediaQuery.paddingOf(context).top + 56;

    return async.when(
      loading: () => Stack(
        children: [
          const Center(child: CircularProgressIndicator()),
          ProStitchCommandHeader(
            avatarInitial: user?.name,
            onAvatarTap: () => context.go('/profile'),
          ),
        ],
      ),
      error: (_, __) => Stack(
        children: [
          Center(
            child: Text(
              "Couldn't load command center.",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          ProStitchCommandHeader(
            avatarInitial: user?.name,
            onAvatarTap: () => context.go('/profile'),
          ),
        ],
      ),
      data: (data) {
        final upcoming = (data['appointments'] as List).cast<Map<String, dynamic>>();
        final pendingAll = (data['pending'] as List).cast<Map<String, dynamic>>();
        final listeningRequests = pendingAll
            .where((a) =>
                (a['kind'] as String? ?? '') == 'listening_request' &&
                (a['status'] as String? ?? '') == 'pending')
            .toList();
        final earnings = data['earnings_mtd'] as Map<String, dynamic>;
        final onboarding = data['onboarding'] as Map<String, dynamic>;
        final profile = data['profile'] as Map<String, dynamic>;
        final offersWalkIn = profile['offers_free_listening'] == true;
        final userName = user?.name ?? 'Clinician';
        final title = _clinicianTitle(profile);
        final todayCount = _sessionsToday(upcoming);
        final queue = _consultationQueue(upcoming);
        final coherence = _coherenceLabel(profile);

        return Stack(
          children: [
            RefreshIndicator(
              color: FriendColors.primary,
              onRefresh: () async => ref.invalidate(_dashboardProvider),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  FriendLayout.horizontal,
                  headerInset + 8,
                  FriendLayout.horizontal,
                  FriendLayout.dockClearance + 16,
                ),
                children: [
                  _IdentityCard(
                    name: userName,
                    title: title,
                    verified: profile['badge_active'] == true ||
                        profile['verification_status'] == 'verified',
                    walkInEnabled: offersWalkIn,
                    crisisFlags: listeningRequests.length,
                    onWalkInChanged: _toggleWalkIn,
                  ),
                  const SizedBox(height: 20),
                  _MetricsStrip(
                    todaySessions: todayCount,
                    mtdEarnings: earnings,
                    coherence: coherence,
                    onEarningsTap: () => context.go('/earnings'),
                  ),
                  if (listeningRequests.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _ListeningSection(
                      requests: listeningRequests,
                      onAccept: (id) => _respondListening(id, true),
                      onDecline: (id) => _respondListening(id, false),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _QueueSection(
                    queue: queue,
                    onLaunchMeet: (id) => context.go('/sessions/$id/host'),
                    onDossier: (client, count) => _openDossier(client, count),
                  ),
                  const SizedBox(height: 20),
                  _EveningWindowsSection(
                    slots: _eveningSlots,
                    onAddSlot: () {
                      setState(() {
                        final hour = 7 + _eveningSlots.length;
                        _eveningSlots.insert(
                          _eveningSlots.length - 1,
                          '${hour % 12}:${15 + _eveningSlots.length * 15} PM',
                        );
                      });
                    },
                    onRemoveSlot: (slot) =>
                        setState(() => _eveningSlots.remove(slot)),
                    onTune: () => context.go('/availability'),
                  ),
                  const SizedBox(height: 20),
                  _OnboardingNudge(onboarding: onboarding),
                  const SizedBox(height: 20),
                  const _PeerSupervisionCard(),
                ],
              ),
            ),
            ProStitchCommandHeader(
              avatarInitial: user?.name,
              onAvatarTap: () => context.go('/profile'),
            ),
          ],
        );
      },
    );
  }
}

String _clinicianTitle(Map<String, dynamic> profile) {
  final category = profile['category'];
  if (category is Map && category['name'] is String) {
    return category['name'] as String;
  }
  final bio = profile['bio'] as String?;
  if (bio != null && bio.isNotEmpty) {
    return bio.length > 48 ? '${bio.substring(0, 48)}…' : bio;
  }
  return 'Licensed practitioner';
}

int _sessionsToday(List<Map<String, dynamic>> appts) {
  final now = DateTime.now();
  var count = 0;
  for (final a in appts) {
    if (a['status'] == 'cancelled') continue;
    final when = DateTime.tryParse(a['scheduled_at'] as String? ?? '');
    if (when == null) continue;
    if (when.year == now.year && when.month == now.month && when.day == now.day) {
      count++;
    }
  }
  return count;
}

List<Map<String, dynamic>> _consultationQueue(List<Map<String, dynamic>> appts) {
  final now = DateTime.now().subtract(const Duration(minutes: 30));
  final list = <Map<String, dynamic>>[];
  for (final a in appts) {
    if (a['status'] == 'cancelled') continue;
    final when = DateTime.tryParse(a['scheduled_at'] as String? ?? '');
    if (when == null || when.isBefore(now)) continue;
    list.add(a);
  }
  list.sort((a, b) {
    final ta = DateTime.parse(a['scheduled_at'] as String);
    final tb = DateTime.parse(b['scheduled_at'] as String);
    return ta.compareTo(tb);
  });
  return list;
}

String _coherenceLabel(Map<String, dynamic> profile) {
  final rating = (profile['rating_avg'] as num?)?.toDouble();
  if (rating != null && rating > 0) {
    return '${(rating / 5 * 100).round()}%';
  }
  return '—';
}

String _formatMtd(Map<String, dynamic> earnings) {
  final cents = (earnings['total_cents'] as int? ?? 0) / 100;
  final currency = earnings['currency'] as String? ?? 'ETB';
  if (cents >= 1000) {
    return '${(cents / 1000).toStringAsFixed(1)}k $currency';
  }
  return '${cents.toStringAsFixed(0)} $currency';
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.name,
    required this.title,
    required this.verified,
    required this.walkInEnabled,
    required this.crisisFlags,
    required this.onWalkInChanged,
  });

  final String name;
  final String title;
  final bool verified;
  final bool walkInEnabled;
  final int crisisFlags;
  final ValueChanged<bool> onWalkInChanged;

  @override
  Widget build(BuildContext context) {
    return ProStitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  FriendAvatar(
                    size: 56,
                    initials: name.isNotEmpty ? name[0] : '?',
                    verified: verified,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: FriendColors.secondaryFixedDim,
                        border: Border.all(color: FriendColors.surfaceLowest, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: FriendColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (verified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 18, color: FriendColors.primary),
                        ],
                      ],
                    ),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: FriendColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () {},
                icon: const Icon(Icons.edit_note_outlined, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: FriendColors.recessed,
                  borderRadius: BorderRadius.circular(FriendRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: FriendColors.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Triage Sentinel: $crisisFlags Crisis Flags',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: FriendColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const ProStitchMicroLabel('Online Walk-in'),
                  Switch.adaptive(
                    value: walkInEnabled,
                    activeTrackColor: FriendColors.primary,
                    onChanged: onWalkInChanged,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricsStrip extends StatelessWidget {
  const _MetricsStrip({
    required this.todaySessions,
    required this.mtdEarnings,
    required this.coherence,
    this.onEarningsTap,
  });

  final int todaySessions;
  final Map<String, dynamic> mtdEarnings;
  final String coherence;
  final VoidCallback? onEarningsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Icons.event_available_outlined,
            tag: 'Today',
            value: '$todaySessions',
            caption: 'Sessions Booked',
            onTap: onEarningsTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricTile(
            icon: Icons.account_balance_wallet_outlined,
            tag: 'MTD',
            value: _formatMtd(mtdEarnings).split(' ').first,
            caption: '${mtdEarnings['currency'] ?? 'ETB'} Escrow',
            onTap: onEarningsTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricTile(
            icon: Icons.psychology_outlined,
            tag: 'Bio',
            value: coherence,
            caption: 'Avg Coherence',
            valueColor: FriendColors.accent,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.tag,
    required this.value,
    required this.caption,
    this.onTap,
    this.valueColor,
  });

  final IconData icon;
  final String tag;
  final String value;
  final String caption;
  final VoidCallback? onTap;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FriendColors.surfaceLowest,
      borderRadius: BorderRadius.circular(FriendRadii.card),
      elevation: 0,
      shadowColor: FriendColors.ink.withValues(alpha: 0.04),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FriendRadii.card),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FriendRadii.card),
            boxShadow: FriendElevation.card,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 18, color: FriendColors.primary),
                  ProStitchMicroLabel(tag),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: valueColor ?? FriendColors.textPrimary,
                ),
              ),
              Text(
                caption,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: FriendColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueSection extends StatelessWidget {
  const _QueueSection({
    required this.queue,
    required this.onLaunchMeet,
    required this.onDossier,
  });

  final List<Map<String, dynamic>> queue;
  final void Function(String id) onLaunchMeet;
  final void Function(Map<String, dynamic> client, int count) onDossier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Consultation Queue',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: FriendColors.primaryLight,
                borderRadius: BorderRadius.circular(FriendRadii.pill),
              ),
              child: Text(
                'Live Stream',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: FriendColors.primaryDeep,
                ),
              ),
            ),
            const Spacer(),
            Text(
              'Timeline',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: FriendColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (queue.isEmpty)
          ProStitchCard(
            child: Column(
              children: [
                Icon(Icons.event_available, size: 40, color: FriendColors.textMuted),
                const SizedBox(height: 8),
                Text(
                  'No upcoming consultations',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bookings from clients will appear here.',
                  style: TextStyle(color: FriendColors.textSecondary),
                ),
              ],
            ),
          )
        else ...[
          _ActiveQueueCard(
            appt: queue.first,
            onLaunchMeet: onLaunchMeet,
            onDossier: onDossier,
          ),
          if (queue.length > 1) ...[
            const SizedBox(height: 10),
            for (final a in queue.skip(1).take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CompactQueueCard(appt: a, onDossier: onDossier),
              ),
          ],
        ],
      ],
    );
  }
}

class _ActiveQueueCard extends StatelessWidget {
  const _ActiveQueueCard({
    required this.appt,
    required this.onLaunchMeet,
    required this.onDossier,
  });

  final Map<String, dynamic> appt;
  final void Function(String id) onLaunchMeet;
  final void Function(Map<String, dynamic> client, int count) onDossier;

  @override
  Widget build(BuildContext context) {
    final startsAt = DateTime.parse(appt['scheduled_at'] as String).toLocal();
    final guest = (appt['client'] as Map<String, dynamic>?) ?? const {};
    final name = guest['name'] as String? ?? 'Client';
    final id = '${appt['id']}';
    final mins = startsAt.difference(DateTime.now()).inMinutes;
    final startsLabel = mins > 0 && mins < 24 * 60
        ? 'Starts in $mins min'
        : DateFormat('h:mm a').format(startsAt);
    final note = appt['client_note'] as String?;

    return ProStitchCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProStitchLivePill(label: startsLabel),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('h:mm a').format(startsAt)} (50m)',
                style: GoogleFonts.inter(fontSize: 12, color: FriendColors.textSecondary),
              ),
              const Spacer(),
              const Icon(Icons.lock_outline, size: 16, color: FriendColors.primary),
              const SizedBox(width: 4),
              const ProStitchMicroLabel('E2EE Video'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Session • ${appt['kind'] ?? 'scheduled'}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: FriendColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: FriendColors.recessed,
              borderRadius: BorderRadius.circular(FriendRadii.small),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ProStitchMicroLabel('Intake note'),
                      Text(
                        note?.isNotEmpty == true ? note! : 'No intake on file',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ProStitchMicroLabel('Active homework'),
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 14, color: FriendColors.accent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Thought log pending',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => onLaunchMeet(id),
                  icon: const Icon(Icons.videocam),
                  label: const Text('Launch Akilil Meet'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FriendRadii.pill),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => onDossier(guest, 1),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FriendRadii.pill),
                  ),
                  backgroundColor: FriendColors.recessed,
                ),
                child: const Icon(Icons.folder_shared_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactQueueCard extends StatelessWidget {
  const _CompactQueueCard({
    required this.appt,
    required this.onDossier,
  });

  final Map<String, dynamic> appt;
  final void Function(Map<String, dynamic> client, int count) onDossier;

  @override
  Widget build(BuildContext context) {
    final startsAt = DateTime.parse(appt['scheduled_at'] as String).toLocal();
    final guest = (appt['client'] as Map<String, dynamic>?) ?? const {};
    final name = guest['name'] as String? ?? 'Client';
    final note = appt['client_note'] as String?;

    return ProStitchCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                child: Text(name.isNotEmpty ? name[0] : '?'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                    Text(
                      '${DateFormat('h:mm a').format(startsAt)} • ${note ?? 'Upcoming session'}',
                      style: GoogleFonts.inter(fontSize: 13, color: FriendColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FriendColors.recessed,
                  borderRadius: BorderRadius.circular(FriendRadii.pill),
                ),
                child: Text(
                  'Escrow Sealed',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: FriendColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ProStitchMicroLabel(
                  appt['kind'] == 'listening_request' ? 'Walk-in focus' : 'Scheduled sync',
                ),
              ),
              TextButton(
                onPressed: () => onDossier(guest, 1),
                child: const Text('Review Notes'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EveningWindowsSection extends StatelessWidget {
  const _EveningWindowsSection({
    required this.slots,
    required this.onAddSlot,
    required this.onRemoveSlot,
    required this.onTune,
  });

  final List<String> slots;
  final VoidCallback onAddSlot;
  final ValueChanged<String> onRemoveSlot;
  final VoidCallback onTune;

  @override
  Widget build(BuildContext context) {
    return ProStitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evening Open Windows',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Instant slots visible to network triage',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: FriendColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: onTune, icon: const Icon(Icons.tune)),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < slots.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InputChip(
                      label: Text(slots[i]),
                      avatar: const Icon(Icons.schedule, size: 16),
                      onDeleted: slots[i].contains('Standby') ? null : () => onRemoveSlot(slots[i]),
                      backgroundColor: i == 0
                          ? FriendColors.secondaryFixed
                          : FriendColors.recessed,
                    ),
                  ),
                ActionChip(
                  label: const Text('Open Extra Slot'),
                  avatar: const Icon(Icons.add, size: 16),
                  onPressed: onAddSlot,
                  backgroundColor: FriendColors.primaryLight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListeningSection extends StatelessWidget {
  const _ListeningSection({
    required this.requests,
    required this.onAccept,
    required this.onDecline,
  });

  final List<Map<String, dynamic>> requests;
  final void Function(int id) onAccept;
  final void Function(int id) onDecline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Walk-in requests',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        for (final a in requests)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ProStitchCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (a['client'] as Map?)?['name'] as String? ?? 'Client',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                  ),
                  if ((a['client_note'] as String?)?.isNotEmpty == true)
                    Text(a['client_note'] as String),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: () => onAccept((a['id'] as num).toInt()),
                        child: const Text('Accept & join'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => onDecline((a['id'] as num).toInt()),
                        child: const Text('Decline'),
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
    final pending = (onboarding['pending_steps'] as List? ?? const []).cast<String>();
    if (pending.isEmpty) return const SizedBox.shrink();
    return ProStitchCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.checklist, color: FriendColors.accent),
        title: const Text('Finish setting up your practice'),
        subtitle: Text('Remaining: ${pending.join(", ")}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/onboarding'),
      ),
    );
  }
}

class _PeerSupervisionCard extends StatelessWidget {
  const _PeerSupervisionCard();

  @override
  Widget build(BuildContext context) {
    return ProStitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: FriendColors.primaryLight,
                child: const Icon(Icons.psychology, size: 18, color: FriendColors.primaryDeep),
              ),
              const SizedBox(width: 8),
              const ProStitchMicroLabel('Clinical Peer Governance'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FriendColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(FriendRadii.pill),
                ),
                child: Text(
                  'CME Credited',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Monthly supervision check-in',
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Text(
            'Schedule peer review through your clinic calendar.',
            style: GoogleFonts.inter(fontSize: 13, color: FriendColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
