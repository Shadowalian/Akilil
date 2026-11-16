import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';
import '../../router.dart';
import 'pillar_provider.dart';

const _ethiopicFallback = ['NotoSansEthiopic'];

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

class _FilterState {
  const _FilterState({
    this.language,
    this.maxPriceCents,
    this.badgeOnly = false,
  });

  final String? language;
  final int? maxPriceCents;
  final bool badgeOnly;

  Map<String, dynamic> toQuery(String category) => {
        'category': category,
        if (language != null && language!.isNotEmpty) 'language': language,
        if (maxPriceCents != null) 'max_price_cents': maxPriceCents,
        if (badgeOnly) 'badge_only': 1,
      };

  _FilterState copyWith({
    String? language,
    int? maxPriceCents,
    bool? badgeOnly,
  }) =>
      _FilterState(
        language: language ?? this.language,
        maxPriceCents: maxPriceCents ?? this.maxPriceCents,
        badgeOnly: badgeOnly ?? this.badgeOnly,
      );
}

final _filterProvider =
    StateProvider<_FilterState>((ref) => const _FilterState());

/// Client-only chip id (e.g. `all`, `orthodox`, `psychiatrists`).
final _discoverChipProvider = StateProvider<String>((ref) => 'all');

final _prosFutureProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final filters = ref.watch(_filterProvider);
  final pillar = ref.watch(discoverPillarProvider);
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>(
    '/professionals',
    queryParameters: filters.toQuery(pillar),
  );
  return res.data ?? const {};
});

/// Explore — C04 Spiritual care · C05 Chef · C06 Psychiatry.
class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  static const _heroHeight = 240.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prosAsync = ref.watch(_prosFutureProvider);
    final category = ref.watch(discoverPillarProvider);
    final s = ref.watch(stringsProvider);

    ref.listen<String>(discoverPillarProvider, (previous, next) {
      ref.read(_discoverChipProvider.notifier).state = 'all';
    });

    return FriendTabScaffold(
      body: prosAsync.when(
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DiscoveryHero(
              height: _heroHeight,
              category: category,
              onFilters: () => _showFilters(context, ref),
            ),
            const Expanded(
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ],
        ),
        error: (e, st) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DiscoveryHero(
              height: _heroHeight,
              category: category,
              onFilters: () => _showFilters(context, ref),
            ),
            Expanded(
              child: FriendEmptyState(
                icon: Icons.cloud_off_outlined,
                title: s.couldntLoadPros,
                message: s.checkConnection,
                ctaLabel: s.retry,
                onCta: () => ref.invalidate(_prosFutureProvider),
              ),
            ),
          ],
        ),
        data: (data) {
          final raw = (data['data'] as List? ?? const [])
              .cast<Map<String, dynamic>>();
          final chip = ref.watch(_discoverChipProvider);
          final filtered =
              _applyChipFilter(raw, category, chip, ref.watch(stringsProvider));

          if (raw.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DiscoveryHero(
                  height: _heroHeight,
                  category: category,
                  onFilters: () => _showFilters(context, ref),
                ),
                Expanded(
                  child: FriendEmptyState(
                    icon: Icons.travel_explore,
                    title: s.noMatches,
                    message: s.tryAnotherPillar,
                    ctaLabel: s.adjustFilters,
                    onCta: () => _showFilters(context, ref),
                  ),
                ),
              ],
            );
          }

          return RefreshIndicator(
            color: FriendColors.primary,
            onRefresh: () async => ref.invalidate(_prosFutureProvider),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _DiscoveryHero(
                    height: _heroHeight,
                    category: category,
                    onFilters: () => _showFilters(context, ref),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _FaithChipsRow(
                    category: category,
                    selected: chip,
                    onSelected: (id) =>
                        ref.read(_discoverChipProvider.notifier).state = id,
                  ),
                ),
                if (_showsLiveCard(category))
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _LiveNowCard(category: category),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            s.prosSectionTitle(category),
                            style: _geist(
                              context,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: FriendColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          s.sortedByMatch,
                          style: _geist(
                            context,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: FriendColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: FriendEmptyState(
                      icon: Icons.filter_alt_outlined,
                      title: s.noMatches,
                      message: s.tryAnotherPillar,
                      ctaLabel: s.chipAll,
                      onCta: () =>
                          ref.read(_discoverChipProvider.notifier).state =
                              'all',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, i) =>
                          _ProListRow(pro: filtered[i]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _showsLiveCard(String category) =>
      category == 'spiritual-psychiatry' || category == 'cooking';

  List<Map<String, dynamic>> _applyChipFilter(
    List<Map<String, dynamic>> list,
    String pillar,
    String chip,
    S s,
  ) {
    if (chip == 'all') return list;
    final needle = _chipSearchTerm(chip, s)?.toLowerCase();
    if (needle == null || needle.isEmpty) return list;
    return list.where((pro) {
      final text = _proSearchBlob(pro);
      return text.contains(needle);
    }).toList();
  }

  String? _chipSearchTerm(String chip, S s) {
    switch (chip) {
      case 'orthodox':
        return s.faithOrthodox;
      case 'muslim':
        return s.faithMuslim;
      case 'protestant':
        return s.faithProtestant;
      case 'catholic':
        return s.faithCatholic;
      case 'psychiatrists':
        return 'psychiatr';
      case 'psychologists':
        return 'psycholog';
      case 'counselors':
        return 'counsel';
      default:
        return chip;
    }
  }

  String _proSearchBlob(Map<String, dynamic> pro) {
    final name = pro['display_name'] as String? ??
        (pro['user'] as Map?)?['name'] as String? ??
        '';
    final category = pro['category'] as Map<String, dynamic>?;
    final specialty = category?['name'] as String? ?? '';
    final title = pro['title'] as String? ?? pro['headline'] as String? ?? '';
    final bio = pro['bio'] as String? ?? '';
    return '$name $specialty $title $bio'.toLowerCase();
  }

  void _showFilters(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FriendColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(FriendRadii.large),
        ),
      ),
      builder: (_) => const _FilterSheet(),
    );
  }
}

class _DiscoveryHero extends ConsumerWidget {
  const _DiscoveryHero({
    required this.height,
    required this.category,
    required this.onFilters,
  });

  final double height;
  final String category;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final title = s.pillarName(category);
    final subtitle = s.pillarSubtitle(category);
    final asset = s.discoverHeroAsset(category);
    final top = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: height + top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: top,
            left: 0,
            right: 0,
            height: height,
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => ColoredBox(
                color: FriendColors.primaryDeep,
              ),
            ),
          ),
          Positioned(
            top: top,
            left: 0,
            right: 0,
            height: height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: top + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _HeroCircleButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => context.go(AppRoutes.today),
                ),
                const Spacer(),
                _HeroCircleButton(
                  icon: Icons.search_rounded,
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                _HeroCircleButton(
                  icon: Icons.tune_rounded,
                  onPressed: onFilters,
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: _geist(
                    context,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.1,
                    color: Colors.white,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: _geist(
                      context,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      color: Colors.white.withValues(alpha: 0.92),
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
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(10),
        ),
      ),
    );
  }
}

class _FaithChipsRow extends ConsumerWidget {
  const _FaithChipsRow({
    required this.category,
    required this.selected,
    required this.onSelected,
  });

  final String category;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final chips = _chipsFor(category, s);
    if (chips.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (id, label) = chips[i];
          return _DiscoverChip(
            label: label,
            selected: selected == id,
            onTap: () => onSelected(id),
          );
        },
      ),
    );
  }

  List<(String, String)> _chipsFor(String pillar, S s) {
    switch (pillar) {
      case 'spiritual-psychiatry':
        return [
          ('all', s.chipAll),
          ('orthodox', s.faithOrthodox),
          ('muslim', s.faithMuslim),
          ('protestant', s.faithProtestant),
          ('catholic', s.faithCatholic),
        ];
      case 'psychiatry':
        return [
          ('all', s.chipAll),
          ('psychiatrists', s.chipPsychiatrists),
          ('psychologists', s.chipPsychologists),
          ('counselors', s.chipCounselors),
        ];
      case 'cooking':
        return [('all', s.chipAll)];
      default:
        return [('all', s.chipAll)];
    }
  }
}

class _DiscoverChip extends StatelessWidget {
  const _DiscoverChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FriendRadii.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? FriendColors.ink : FriendColors.surfaceLowest,
            borderRadius: BorderRadius.circular(FriendRadii.pill),
            border: Border.all(
              color: selected ? FriendColors.ink : FriendColors.border,
            ),
          ),
          child: Text(
            label,
            style: _geist(
              context,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : FriendColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveNowCard extends ConsumerWidget {
  const _LiveNowCard({required this.category});

  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final cooking = category == 'cooking';
    final title = cooking ? s.liveChefShiro : s.liveEveningPrayer;
    final meta = cooking ? s.liveChefTsion : s.liveMemhirDaniel;

    return Material(
      color: FriendColors.surfaceLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FriendRadii.large),
        side: const BorderSide(color: FriendColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.liveNow.toUpperCase(),
              style: _geist(
                context,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: FriendColors.primaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: _geist(
                context,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: FriendColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              meta,
              style: _geist(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: FriendColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: () => context.go(AppRoutes.groups),
                style: FilledButton.styleFrom(
                  backgroundColor: FriendColors.ink,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FriendRadii.pill),
                  ),
                ),
                child: Text(
                  s.join,
                  style: _geist(
                    context,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProListRow extends ConsumerWidget {
  const _ProListRow({required this.pro});

  final Map<String, dynamic> pro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final name = pro['display_name'] as String? ??
        (pro['user'] as Map?)?['name'] as String? ??
        'Professional';
    final avatar = pro['avatar_url'] as String? ??
        (pro['user'] as Map?)?['avatar_url'] as String?;
    final category = pro['category'] as Map<String, dynamic>?;
    final pillar = AkililPillars.bySlug(category?['slug'] as String?);
    final specialty = category?['name'] as String? ??
        pro['title'] as String? ??
        pillar?.name ??
        'Akilil';
    final rate = pro['hourly_rate_cents'] as int? ?? 0;
    final badge = pro['badge_active'] == true;
    final ratingAvg = (pro['rating_avg'] as num?)?.toDouble() ?? 0;
    final ratingCount = pro['rating_count'] as int? ?? 0;
    final id = '${pro['id']}';

    final priceLabel = rate <= 0 ? s.free : s.priceEtb((rate / 100).round());

    return Material(
      color: FriendColors.surfaceLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FriendRadii.large),
        side: const BorderSide(color: FriendColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/pros/$id'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FriendAvatar(
                size: 52,
                imageUrl: avatar,
                initials: name.isNotEmpty ? name[0].toUpperCase() : '?',
                verified: badge,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _geist(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: FriendColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      specialty,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _geist(
                        context,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: FriendColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceLabel,
                    style: _geist(
                      context,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: FriendColors.textPrimary,
                    ),
                  ),
                  if (ratingCount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: FriendColors.accent,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          ratingAvg.toStringAsFixed(1),
                          style: _geist(
                            context,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: FriendColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();
  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late String _category;
  String? _language;
  int? _maxPrice;
  bool _badgeOnly = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(_filterProvider);
    _category = ref.read(discoverPillarProvider);
    _language = s.language;
    _maxPrice = s.maxPriceCents;
    _badgeOnly = s.badgeOnly;
  }

  @override
  Widget build(BuildContext context) {
    const langs = [
      ('en', 'English'),
      ('am', 'Amharic'),
      ('om', 'Oromo'),
      ('sw', 'Swahili'),
    ];
    const prices = [
      (null, 'Any'),
      (2500, '250 ETB'),
      (5000, '500 ETB'),
      (10000, '1000 ETB'),
    ];
    final s = ref.watch(stringsProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: FriendColors.border,
                  borderRadius: BorderRadius.circular(FriendRadii.pill),
                ),
              ),
            ),
            Text(
              s.filters,
              style: _geist(
                context,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: FriendColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.tryAnotherPillar,
              style: _geist(
                context,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: FriendColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            FriendPillarPicker(
              selectedSlug: _category,
              compact: true,
              nameOf: (p) => ref.watch(stringsProvider).pillarName(p.slug),
              subtitleOf: (p) =>
                  ref.watch(stringsProvider).pillarSubtitle(p.slug),
              onSelected: (slug) => setState(
                () => _category = slug ?? AkililPillars.defaultSlug,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              s.language,
              style: _geist(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: FriendColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (code, label) in langs)
                  _FilterChip(
                    label: label,
                    selected: _language == code,
                    onTap: () => setState(
                      () => _language = _language == code ? null : code,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Max price / session',
              style: _geist(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: FriendColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (cents, label) in prices)
                  _FilterChip(
                    label: label,
                    selected: _maxPrice == cents,
                    onTap: () => setState(() => _maxPrice = cents),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Material(
              color: FriendColors.primaryLight.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(FriendRadii.medium),
              child: InkWell(
                onTap: () => setState(() => _badgeOnly = !_badgeOnly),
                borderRadius: BorderRadius.circular(FriendRadii.medium),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.verifiedListener,
                          style: _geist(
                            context,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: FriendColors.textPrimary,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 48,
                        height: 30,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(FriendRadii.pill),
                          color: _badgeOnly
                              ? FriendColors.primary
                              : FriendColors.border,
                        ),
                        alignment: _badgeOnly
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FriendGlowButton(
              label: s.filters,
              expanded: true,
              showArrow: true,
              onPressed: () {
                ref.read(discoverPillarProvider.notifier).state = _category;
                ref.read(_filterProvider.notifier).state = _FilterState(
                  language: _language,
                  maxPriceCents: _maxPrice,
                  badgeOnly: _badgeOnly,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FriendRadii.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? FriendColors.primary : FriendColors.surface,
            borderRadius: BorderRadius.circular(FriendRadii.pill),
            border: Border.all(
              color: selected ? FriendColors.primary : FriendColors.border,
            ),
          ),
          child: Text(
            label,
            style: _geist(
              context,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected
                  ? FriendColors.onPrimary
                  : FriendColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}