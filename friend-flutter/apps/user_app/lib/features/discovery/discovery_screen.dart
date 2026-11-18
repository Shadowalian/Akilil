import 'package:friend_user/l10n/tr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';
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

/// Free-text search within the current pillar.
final _searchProvider = StateProvider.autoDispose<String>((ref) => '');

/// Explore: switch between the three pillars, search, narrow with chips,
/// and browse the people who fit.
class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prosAsync = ref.watch(_prosFutureProvider);
    final category = ref.watch(discoverPillarProvider);
    final chip = ref.watch(_discoverChipProvider);
    final query = ref.watch(_searchProvider).trim().toLowerCase();
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);

    ref.listen<String>(discoverPillarProvider, (previous, next) {
      ref.read(_discoverChipProvider.notifier).state = 'all';
    });

    final header = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 20, FriendLayout.horizontal, 16),
          child: Row(
            children: [
              Expanded(
                child: Semantics(header: true, child: Text(s.exploreNav, style: theme.textTheme.headlineLarge)),
              ),
              FriendIconChip(
                icon: Icons.tune_rounded,
                tooltip: s.adjustFilters,
                onPressed: () => _showFilters(context, ref),
              ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FriendLayout.horizontal),
          child: _PillarTabs(selected: category, onSelected: (slug) => ref.read(discoverPillarProvider.notifier).state = slug),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 12, FriendLayout.horizontal, 0),
          child: TextField(
            onChanged: (v) => ref.read(_searchProvider.notifier).state = v,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: tr('Search by name, language or what they help with'),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              fillColor: FriendColors.recessed,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FriendRadii.medium),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: _FaithChipsRow(
          category: category,
          selected: chip,
          onSelected: (id) => ref.read(_discoverChipProvider.notifier).state = id,
        ),
      ),
      if (_showsLiveCard(category))
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 16, FriendLayout.horizontal, 0),
            child: _LiveNowCard(category: category),
          ),
        ),
    ];

    Widget body(List<Widget> rest) => RefreshIndicator(
          color: FriendColors.primary,
          backgroundColor: FriendColors.surface,
          onRefresh: () async => ref.invalidate(_prosFutureProvider),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [...header, ...rest],
          ),
        );

    return FriendTabScaffold(
      body: prosAsync.when(
        loading: () => body([
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
          ),
        ]),
        error: (e, st) => body([
          SliverFillRemaining(
            hasScrollBody: false,
            child: FriendEmptyState(
              icon: Icons.cloud_off_outlined,
              title: s.couldntLoadPros,
              message: s.checkConnection,
              ctaLabel: s.retry,
              onCta: () => ref.invalidate(_prosFutureProvider),
            ),
          ),
        ]),
        data: (data) {
          final raw = (data['data'] as List? ?? const []).cast<Map<String, dynamic>>();
          var filtered = _applyChipFilter(raw, category, chip, s);
          if (query.isNotEmpty) {
            filtered = filtered.where((p) => _proSearchBlob(p).contains(query)).toList();
          }
          return body([
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 24, FriendLayout.horizontal, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: Text(s.prosSectionTitle(category), style: theme.textTheme.titleMedium)),
                    if (filtered.isNotEmpty)
                      Text(s.sortedByMatch, style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: FriendEmptyState(
                  icon: Icons.search_off_rounded,
                  title: s.noMatches,
                  message: s.tryAnotherPillar,
                  ctaLabel: raw.isEmpty ? s.adjustFilters : s.chipAll,
                  onCta: raw.isEmpty
                      ? () => _showFilters(context, ref)
                      : () => ref.read(_discoverChipProvider.notifier).state = 'all',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 0, FriendLayout.horizontal, 32),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _ProListRow(pro: filtered[i]),
                ),
              ),
          ]);
        },
      ),
    );
  }

  bool _showsLiveCard(String category) => category == 'spiritual-psychiatry' || category == 'cooking';

  List<Map<String, dynamic>> _applyChipFilter(List<Map<String, dynamic>> list, String pillar, String chip, S s) {
    if (chip == 'all') return list;
    // Match on English keywords whatever the UI language: bios and
    // specialties are written in English.
    final needles = switch (chip) {
      'orthodox' => const ['orthodox', 'ኦርቶዶክስ'],
      'muslim' => const ['muslim', 'islam', 'ሙስሊም'],
      'protestant' => const ['protestant', 'evangelical', 'ፕሮቴስታንት'],
      'catholic' => const ['catholic', 'ካቶሊክ'],
      'psychiatrists' => ['psychiatr'],
      'psychologists' => ['psycholog'],
      'counselors' => ['counsel'],
      _ => [chip],
    };
    return list.where((pro) => needles.any(_proSearchBlob(pro).contains)).toList();
  }

  String _proSearchBlob(Map<String, dynamic> pro) {
    final name = pro['display_name'] as String? ?? (pro['user'] as Map?)?['name'] as String? ?? '';
    final category = pro['category'] as Map<String, dynamic>?;
    final specialty = '${category?['name'] ?? ''} ${tr(category?['name'] as String? ?? '')}';
    final title = pro['title'] as String? ?? pro['headline'] as String? ?? '';
    final bio = pro['bio'] as String? ?? '';
    final specialties = ((pro['specialties'] as List?) ?? []).map((e) => e is Map ? e['name'] : e).join(' ');
    final languages = ((pro['languages'] as List?) ?? []).map((e) => e is Map ? '${e['name']} ${e['code']}' : e).join(' ');
    return '$name $specialty $title $bio $specialties $languages'.toLowerCase();
  }

  void _showFilters(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _FilterSheet(),
    );
  }
}

/// Three-way switch between the pillars.
class _PillarTabs extends ConsumerWidget {
  const _PillarTabs({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return SegmentedButton<String>(
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      segments: [
        for (final p in [AkililPillars.psychiatry, AkililPillars.spiritualPsychiatry, AkililPillars.cooking])
          ButtonSegment(
            value: p.slug,
            label: Text(s.pillarShortName(p.slug), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
      selected: {selected},
      onSelectionChanged: (v) => onSelected(v.first),
    );
  }
}

class _FaithChipsRow extends ConsumerWidget {
  const _FaithChipsRow({required this.category, required this.selected, required this.onSelected});

  final String category;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final chips = _chipsFor(category, s);
    if (chips.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 12, FriendLayout.horizontal, 4),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (id, label) = chips[i];
          return FriendStitchFilterPill(label: label, selected: selected == id, onTap: () => onSelected(id));
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
      default:
        return [('all', s.chipAll)];
    }
  }
}

/// What is actually live in this pillar right now (nothing → no card).
final _liveInPillarProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, pillar) async {
  final res = await ref.read(dioProvider).get<Map<String, dynamic>>(
    '/live-streams',
    queryParameters: {'category': pillar, 'status': 'live', 'per_page': 1},
  );
  final list = (res.data?['data'] as List?) ?? const [];
  return list.isEmpty ? null : Map<String, dynamic>.from(list.first as Map);
});

class _LiveNowCard extends ConsumerWidget {
  const _LiveNowCard({required this.category});

  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final stream = ref.watch(_liveInPillarProvider(category)).valueOrNull;
    if (stream == null) return const SizedBox.shrink();

    final host = (stream['host'] as Map?)?['name'] ?? '';
    final watching = (stream['viewer_count'] as num?)?.toInt() ?? 0;
    final meta = s.t('$host · $watching watching', '$host · $watching ሰዎች እየተመለከቱ ነው');

    return CandyCard(
      onTap: () => context.push('/live/${stream['id']}'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const FriendLivePulse(size: 6),
                    const SizedBox(width: 6),
                    Text(
                      s.liveNow,
                      style: theme.textTheme.labelMedium?.copyWith(color: FriendColors.live, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('${stream['title']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(meta, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () => context.push('/live/${stream['id']}'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 16)),
            child: Text(s.t('Watch', 'ይመልከቱ')),
          ),
        ],
      ),
    );
  }
}

/// A professional in the Explore list.
class _ProListRow extends ConsumerWidget {
  const _ProListRow({required this.pro});

  final Map<String, dynamic> pro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final name = pro['display_name'] as String? ?? (pro['user'] as Map?)?['name'] as String? ?? tr('Professional');
    final avatar = pro['avatar_url'] as String? ?? (pro['user'] as Map?)?['avatar_url'] as String?;
    final category = pro['category'] as Map<String, dynamic>?;
    final pillar = AkililPillars.bySlug(category?['slug'] as String?);
    final specialty = tr(category?['name'] as String? ?? pro['title'] as String? ?? pillar?.name ?? 'Akilil');
    final rate = pro['hourly_rate_cents'] as int? ?? 0;
    final badge = pro['badge_active'] == true;
    final ratingAvg = (pro['rating_avg'] as num?)?.toDouble() ?? 0;
    final ratingCount = pro['rating_count'] as int? ?? 0;
    final years = (pro['experience_years'] as num?)?.toInt() ?? 0;
    final bio = (pro['bio'] as String? ?? '').trim();
    final languages = ((pro['languages'] as List?) ?? const [])
        .map((e) => e is Map ? tr('${e['name'] ?? e['code'] ?? ''}') : '$e')
        .where((e) => e.isNotEmpty)
        .join(', ');
    final id = '${pro['id']}';

    final meta = [
      specialty,
      if (years > 0) s.t('$years yrs experience', 'የ$years ዓመት ልምድ'),
      if (languages.isNotEmpty) languages,
    ].join(' · ');

    return CandyCard(
      onTap: () => context.go('/pros/$id'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FriendAvatar(size: 52, imageUrl: avatar, initials: personInitial(name), verified: badge),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(meta, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              bio,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textPrimary),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              if (ratingCount > 0) ...[
                const Icon(Icons.star_rounded, size: 16, color: FriendColors.pillarCooking),
                const SizedBox(width: 4),
                Text(
                  ratingAvg.toStringAsFixed(1),
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, fontFeatures: friendTabular),
                ),
                const SizedBox(width: 4),
                Text('($ratingCount)', style: theme.textTheme.labelSmall),
              ],
              const Spacer(),
              Text(
                rate <= 0 ? s.free : s.priceEtb((rate / 100).round()),
                style: theme.textTheme.titleSmall?.copyWith(fontFeatures: friendTabular),
              ),
              if (rate > 0)
                Text(s.t(' / session', ' / ቆይታ'), style: theme.textTheme.labelSmall),
            ],
          ),
        ],
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
    final langs = [
      ('en', tr('English')),
      ('am', tr('Amharic')),
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
                fontWeight: FontWeight.w600,
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
                fontWeight: FontWeight.w600,
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
              tr('Max price / session'),
              style: _geist(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w600,
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
              fontWeight: FontWeight.w600,
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