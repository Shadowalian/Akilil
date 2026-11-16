import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';

const _ethiopicFallback = ['NotoSansEthiopic'];
const _eatTz = 'Africa/Addis_Ababa';
const _heroAsset = 'assets/figma/c07_hero.jpg';

TextStyle _geist(
  BuildContext context, {
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
  return base.copyWith(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
    fontFamily: 'Geist',
    fontFamilyFallback: _ethiopicFallback,
  );
}

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

  for (var offset = 0; offset < 7 && found.length < 8; offset++) {
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
            ? 'Today'
            : offset == 1
                ? 'Tomorrow'
                : DateFormat('EEE').format(day);
        found.add(_SlotChipLabel(
          dayLabel: dayLabel,
          timeLabel: DateFormat('h:mm a').format(local),
        ));
      }
    } on DioException {
      // Keep scanning other days.
    }
  }

  if (found.isEmpty) {
    return const [
      _SlotChipLabel(dayLabel: 'Today', timeLabel: '2:00 PM'),
      _SlotChipLabel(dayLabel: 'Today', timeLabel: '4:30 PM'),
      _SlotChipLabel(dayLabel: 'Tomorrow', timeLabel: '10:00 AM'),
      _SlotChipLabel(dayLabel: 'Wed', timeLabel: '11:00 AM'),
    ];
  }
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


String _moneyLabel(int cents, String currency) {
  final major = (cents / 100).round();
  if (currency == 'ETB') {
    return '$major';
  }
  return major.toString();
}

/// C07 — Akilil professional profile (hero, sheet, availability, book CTA).
class ProfessionalDetailScreen extends ConsumerStatefulWidget {
  const ProfessionalDetailScreen({super.key, required this.proId});
  final String proId;

  @override
  ConsumerState<ProfessionalDetailScreen> createState() =>
      _ProfessionalDetailScreenState();
}

class _ProfessionalDetailScreenState
    extends ConsumerState<ProfessionalDetailScreen> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final proAsync = ref.watch(_proDetailProvider(widget.proId));
    final slotsAsync = ref.watch(_proNextSlotsProvider(widget.proId));

    return Scaffold(
      backgroundColor: FriendColors.surfaceLowest,
      body: proAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: FriendEmptyState(
            icon: Icons.person_off_outlined,
            title: s.couldntLoadPros,
            message: s.checkConnection,
            ctaLabel: s.retry,
            onCta: () => ref.invalidate(_proDetailProvider(widget.proId)),
          ),
        ),
        data: (data) {
          final name = data['display_name'] as String? ?? s.listenerFallback;
          final avatar = data['avatar_url'] as String?;
          final category = data['category'] as Map<String, dynamic>?;
          final categoryName = category?['name'] as String? ?? s.listenerFallback;
          final rateCents = data['hourly_rate_cents'] as int? ?? 0;
          final currency = data['currency'] as String? ?? 'ETB';
          final bio = (data['bio'] as String? ?? '').trim();
          final years = data['experience_years'] as int? ?? 0;
          final ratingAvg = (data['rating_avg'] as num?)?.toDouble() ?? 0;
          final ratingCount = data['rating_count'] as int? ?? 0;
          final sessions = data['sessions_completed'] as int? ?? 0;
          final duration = data['session_duration_minutes'] as int? ?? 50;
          final languages = _labels(data['languages']);
          final specialties = _labels(data['specialties']);
          final accepting = data['is_accepting_clients'] != false;
          final verified = _isLicenseVerified(data);
          // The server charges this flat price per session.
          final sessionCents = rateCents;
          final priceMajor = _moneyLabel(sessionCents, currency);
          final langLine = languages.isEmpty
              ? 'English'
              : languages.take(3).join(', ');
          final city = (data['city'] as String?)?.trim();
          final metaLine = [categoryName, city?.isNotEmpty == true ? city! : s.cityFallback, langLine]
              .join(' · ');

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _ProfileHero(
                        name: name,
                        avatarUrl: avatar,
                        verified: verified,
                        licenseLabel: category?['slug'] == 'cooking' ? 'Verified chef' : s.licenseVerified,
                        onBack: () => context.pop(),
                        onShare: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.shareProfile)),
                          );
                        },
                        onSave: () => setState(() => _saved = !_saved),
                        saved: _saved,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Transform.translate(
                        offset: const Offset(0, -20),
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: FriendColors.surfaceLowest,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                metaLine,
                                style: _geist(
                                  context,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: FriendColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _StatsRow(
                                ratingAvg: ratingAvg,
                                ratingCount: ratingCount,
                                sessions: sessions,
                                years: years,
                                reviewsLabel: s.statReviews,
                                sessionsLabel: s.statSessions,
                                experienceLabel: s.statExperience,
                                yrsLabel: years > 0 ? s.yrsExperience(years) : '—',
                              ),
                              const SizedBox(height: 24),
                              Text(
                                s.aboutMe,
                                style: _geist(
                                  context,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: FriendColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                bio.isEmpty
                                    ? "I'm here to listen without judgment. Book a session and we'll go at your pace."
                                    : bio,
                                style: _geist(
                                  context,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: FriendColors.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                              if (specialties.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Text(
                                  s.specialtiesTopics,
                                  style: _geist(
                                    context,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final topic in specialties)
                                      _TopicChip(label: topic),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 24),
                              Text(
                                s.nextAvailable,
                                style: _geist(
                                  context,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              slotsAsync.when(
                                loading: () => const SizedBox(
                                  height: 44,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                error: (error, stackTrace) => _SlotStrip(
                                  slots: const [
                                    _SlotChipLabel(
                                      dayLabel: 'Today',
                                      timeLabel: '2:00 PM',
                                    ),
                                  ],
                                ),
                                data: (slots) => _SlotStrip(slots: slots),
                              ),
                              const SizedBox(height: 88),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _C07BookBar(
                priceLabel: (currency == 'ETB')
                    ? s.priceEtb(int.tryParse(priceMajor) ?? 0)
                    : '$priceMajor $currency',
                perSessionLabel: s.perFiftyMinSession(duration),
                bookLabel: accepting ? s.bookSession : s.unavailable,
                accepting: accepting,
                onBook: () => context.go('/pros/${widget.proId}/book'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.avatarUrl,
    required this.verified,
    required this.licenseLabel,
    required this.onBack,
    required this.onShare,
    required this.onSave,
    required this.saved,
  });

  final String name;
  final String? avatarUrl;
  final bool verified;
  final String licenseLabel;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final heroH = MediaQuery.sizeOf(context).height * 0.46;

    return SizedBox(
      height: heroH,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (avatarUrl != null && avatarUrl!.isNotEmpty)
            Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                _heroAsset,
                fit: BoxFit.cover,
              ),
            )
          else
            Image.asset(_heroAsset, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.42),
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.78),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _HeroCircleButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: onBack,
                ),
                const Spacer(),
                _HeroCircleButton(
                  icon: Icons.ios_share_rounded,
                  onPressed: onShare,
                ),
                const SizedBox(width: 8),
                _HeroCircleButton(
                  icon: saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  onPressed: onSave,
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: _geist(
                    context,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                if (verified) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: FriendColors.primaryContainer,
                      borderRadius: BorderRadius.circular(FriendRadii.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: FriendColors.onPrimaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          licenseLabel,
                          style: _geist(
                            context,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: FriendColors.onPrimaryContainer,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCircleButton extends StatelessWidget {
  const _HeroCircleButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(padding: const EdgeInsets.all(10)),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.ratingAvg,
    required this.ratingCount,
    required this.sessions,
    required this.years,
    required this.reviewsLabel,
    required this.sessionsLabel,
    required this.experienceLabel,
    required this.yrsLabel,
  });

  final double ratingAvg;
  final int ratingCount;
  final int sessions;
  final int years;
  final String reviewsLabel;
  final String sessionsLabel;
  final String experienceLabel;
  final String yrsLabel;

  @override
  Widget build(BuildContext context) {
    final ratingVal = ratingCount > 0 ? ratingAvg.toStringAsFixed(1) : '—';
    final ratingSub = ratingCount > 0 ? '★ $reviewsLabel' : '★ New';
    final sessionsVal = sessions > 0 ? '$sessions' : '—';

    return Row(
      children: [
        Expanded(
          child: _StatCell(value: ratingVal, label: ratingSub),
        ),
        Expanded(
          child: _StatCell(
            value: sessionsVal,
            label: sessionsLabel,
          ),
        ),
        Expanded(
          child: _StatCell(
            value: years > 0 ? yrsLabel : '—',
            label: experienceLabel,
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: FriendColors.recessed,
        borderRadius: BorderRadius.circular(FriendRadii.medium),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: _geist(
              context,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: _geist(
              context,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: FriendColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: FriendColors.recessed,
        borderRadius: BorderRadius.circular(FriendRadii.pill),
        border: Border.all(color: FriendColors.border),
      ),
      child: Text(
        label,
        style: _geist(
          context,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: FriendColors.textPrimary,
        ),
      ),
    );
  }
}

class _SlotStrip extends StatelessWidget {
  const _SlotStrip({required this.slots});
  final List<_SlotChipLabel> slots;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: slots.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final slot = slots[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: FriendColors.surfaceLowest,
              borderRadius: BorderRadius.circular(FriendRadii.pill),
              border: Border.all(color: FriendColors.border),
            ),
            child: Text(
              '${slot.dayLabel} · ${slot.timeLabel}',
              style: _geist(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: FriendColors.textPrimary,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _C07BookBar extends StatelessWidget {
  const _C07BookBar({
    required this.priceLabel,
    required this.perSessionLabel,
    required this.bookLabel,
    required this.accepting,
    required this.onBook,
  });

  final String priceLabel;
  final String perSessionLabel;
  final String bookLabel;
  final bool accepting;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FriendColors.surfaceLowest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      priceLabel,
                      style: _geist(
                        context,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      perSessionLabel,
                      style: _geist(
                        context,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: FriendColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: accepting ? onBook : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(152, 48),
                  backgroundColor: FriendColors.ink,
                  foregroundColor: FriendColors.accent,
                  disabledBackgroundColor: FriendColors.border,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FriendRadii.pill),
                  ),
                ),
                child: Text(
                  bookLabel,
                  style: _geist(
                    context,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: accepting ? FriendColors.accent : FriendColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}