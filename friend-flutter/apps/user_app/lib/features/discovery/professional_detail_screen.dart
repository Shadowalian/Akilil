import 'package:intl/intl.dart';
import 'package:friend_user/l10n/tr.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';

const _eatTz = 'Africa/Addis_Ababa';

final _proDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/professionals/$id');
  final body = res.data ?? const <String, dynamic>{};
  return (body['data'] as Map<String, dynamic>?) ?? body;
});

final _proNextSlotsProvider = FutureProvider.autoDispose
    .family<List<_SlotChipLabel>, String>((ref, proId) async {
  final dio = ref.read(dioProvider);
  final now = DateTime.now();
  final found = <_SlotChipLabel>[];

  for (var offset = 0; offset < 14 && found.length < 8; offset++) {
    final day = DateTime(now.year, now.month, now.day).add(Duration(days: offset));
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    try {
      final res = await dio.get<Map<String, dynamic>>(
        '/professionals/$proId/available-slots',
        queryParameters: {'date': dateStr, 'timezone': _eatTz},
      );
      final slots = (res.data?['slots'] as List?) ?? const [];
      for (final raw in slots) {
        if (found.length >= 8) break;
        if (raw is! Map) continue;
        final local = DateTime.tryParse(raw['start_local']?.toString() ?? '');
        if (local == null) continue;
        final dayLabel = offset == 0
            ? tr('Today')
            : offset == 1
                ? tr('Tomorrow')
                : trDate('EEE', day);
        found.add(_SlotChipLabel(
          dayLabel: dayLabel,
          timeLabel: trDate('h:mm a', local),
        ));
      }
    } on DioException {
      // Keep scanning other days.
    }
  }

  // No open times: say so, never invent them.
  return found;
});

class _SlotChipLabel {
  const _SlotChipLabel({required this.dayLabel, required this.timeLabel});
  final String dayLabel;
  final String timeLabel;
}

List<String> _labels(Object? raw) {
  return [
    for (final item in (raw as List? ?? const []))
      if (item is Map)
        (item['name'] ?? item['code'] ?? '').toString()
      else
        item.toString(),
  ].where((l) => l.isNotEmpty).toList();
}

bool _isLicenseVerified(Map<String, dynamic> data) {
  if (data['badge_active'] == true) return true;
  if (data['verification_status']?.toString() == 'approved') return true;
  final docs = data['approved_documents'] as List?;
  return docs != null && docs.isNotEmpty;
}



/// A professional's profile: who they are, what they help with, when they
/// are free, and the price, with one way to book.
class ProfessionalDetailScreen extends ConsumerWidget {
  const ProfessionalDetailScreen({super.key, required this.proId});
  final String proId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final proAsync = ref.watch(_proDetailProvider(proId));
    final slotsAsync = ref.watch(_proNextSlotsProvider(proId));

    return Scaffold(
      backgroundColor: FriendColors.background,
      body: SafeArea(
        bottom: false,
        child: proAsync.when(
          loading: () => const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
          error: (e, _) => Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(alignment: Alignment.centerLeft, child: FriendBackButton()),
              ),
              Expanded(
                child: FriendEmptyState(
                  icon: Icons.person_off_outlined,
                  title: s.couldntLoadPros,
                  message: s.checkConnection,
                  ctaLabel: s.retry,
                  onCta: () => ref.invalidate(_proDetailProvider(proId)),
                ),
              ),
            ],
          ),
          data: (data) {
            final name = data['display_name'] as String? ?? s.listenerFallback;
            final avatar = data['avatar_url'] as String?;
            final category = data['category'] as Map<String, dynamic>?;
            final isChef = category?['slug'] == 'cooking';
            final categoryName = category?['name'] is String ? tr(category!['name'] as String) : s.listenerFallback;
            final rateCents = data['hourly_rate_cents'] as int? ?? 0;
            final currency = data['currency'] as String? ?? 'ETB';
            final bio = (data['bio'] as String? ?? '').trim();
            final years = data['experience_years'] as int? ?? 0;
            final ratingAvg = (data['rating_avg'] as num?)?.toDouble() ?? 0;
            final ratingCount = data['rating_count'] as int? ?? 0;
            final sessions = data['sessions_completed'] as int? ?? 0;
            final duration = data['session_duration_minutes'] as int? ?? 50;
            final languages = _labels(data['languages']).map(tr).toList();
            final specialties = _labels(data['specialties']);
            final accepting = data['is_accepting_clients'] != false;
            final verified = _isLicenseVerified(data);
            final city = (data['city'] as String?)?.trim();
            final priceMajor = (rateCents / 100).round();
            void book() => context.go('/pros/$proId/book');

            return Column(
              children: [
                Expanded(
                  child: FriendContentWidth(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 8, FriendLayout.horizontal, 32),
                      children: [
                        const Align(alignment: Alignment.centerLeft, child: FriendBackButton()),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            FriendAvatar(size: 76, imageUrl: avatar, initials: personInitial(name), verified: verified),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Semantics(header: true, child: Text(name, style: theme.textTheme.headlineMedium)),
                                  const SizedBox(height: 4),
                                  Text(
                                    [categoryName, if (city != null && city.isNotEmpty) city].join(' · '),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  if (verified) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.verified_rounded, size: 16, color: FriendColors.primary),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            isChef ? tr('Verified chef') : s.licenseVerified,
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              color: FriendColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _StatsRow(
                          ratingAvg: ratingAvg,
                          ratingCount: ratingCount,
                          sessions: sessions,
                          yearsLabel: years > 0 ? s.yrsExperience(years) : '—',
                          reviewsLabel: s.statReviews,
                          sessionsLabel: s.statSessions,
                          experienceLabel: s.statExperience,
                        ),
                        if (!accepting) ...[
                          const SizedBox(height: 16),
                          CandyCard(
                            tint: FriendColors.warning,
                            child: Text(
                              tr('Not taking new clients right now.'),
                              style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textPrimary),
                            ),
                          ),
                        ],
                        if (bio.isNotEmpty) ...[
                          const SizedBox(height: FriendLayout.sectionGap),
                          FriendSectionLabel(s.aboutMe),
                          Text(bio, style: theme.textTheme.bodyMedium),
                        ],
                        if (specialties.isNotEmpty) ...[
                          const SizedBox(height: FriendLayout.sectionGap),
                          FriendSectionLabel(s.specialtiesTopics),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [for (final topic in specialties) _TopicChip(label: tr(topic))],
                          ),
                        ],
                        if (languages.isNotEmpty) ...[
                          const SizedBox(height: FriendLayout.sectionGap),
                          FriendSectionLabel(tr('Languages')),
                          Text(languages.join(', '), style: theme.textTheme.bodyMedium),
                        ],
                        const SizedBox(height: FriendLayout.sectionGap),
                        FriendSectionLabel(s.nextAvailable),
                        slotsAsync.when(
                          loading: () => const SizedBox(
                            height: 44,
                            child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                          ),
                          error: (error, stackTrace) => Text(
                            tr("Couldn't load their times. Open booking to see them."),
                            style: theme.textTheme.bodySmall,
                          ),
                          data: (slots) => slots.isEmpty
                              ? Text(tr('No open times in the next two weeks.'), style: theme.textTheme.bodySmall)
                              : _SlotStrip(slots: slots, onTap: accepting ? book : null),
                        ),
                      ],
                    ),
                  ),
                ),
                FriendStitchBookBar(
                  amount: rateCents <= 0 ? s.free : '$priceMajor',
                  currency: rateCents <= 0 ? '' : currency,
                  durationLabel: s.perFiftyMinSession(duration),
                  buttonLabel: accepting ? s.bookSession : s.unavailable,
                  enabled: accepting,
                  onBook: book,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.ratingAvg,
    required this.ratingCount,
    required this.sessions,
    required this.yearsLabel,
    required this.reviewsLabel,
    required this.sessionsLabel,
    required this.experienceLabel,
  });

  final double ratingAvg;
  final int ratingCount;
  final int sessions;
  final String yearsLabel;
  final String reviewsLabel;
  final String sessionsLabel;
  final String experienceLabel;

  @override
  Widget build(BuildContext context) {
    return CandyCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatCell(
                value: ratingCount > 0 ? ratingAvg.toStringAsFixed(1) : '—',
                label: ratingCount > 0 ? '$ratingCount $reviewsLabel' : reviewsLabel,
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _StatCell(value: sessions > 0 ? '$sessions' : '—', label: sessionsLabel)),
            const VerticalDivider(width: 1),
            Expanded(child: _StatCell(value: yearsLabel, label: experienceLabel)),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(fontFeatures: friendTabular),
        ),
        const SizedBox(height: 2),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: FriendColors.recessed, borderRadius: BorderRadius.circular(FriendRadii.pill)),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _SlotStrip extends StatelessWidget {
  const _SlotStrip({required this.slots, this.onTap});

  final List<_SlotChipLabel> slots;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: slots.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final slot = slots[i];
          return Material(
            color: FriendColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FriendRadii.medium),
              side: const BorderSide(color: FriendColors.borderStrong),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(FriendRadii.medium),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(slot.dayLabel, style: theme.textTheme.labelSmall),
                    const SizedBox(height: 2),
                    Text(slot.timeLabel, style: theme.textTheme.titleSmall?.copyWith(fontFeatures: friendTabular)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
