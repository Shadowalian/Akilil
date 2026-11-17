import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../messaging/care_team.dart';

/// Switching is free and private: the current professional is not told why.
/// The reason only shapes who we suggest next.
class SwitchTherapistScreen extends ConsumerStatefulWidget {
  const SwitchTherapistScreen({super.key});

  @override
  ConsumerState<SwitchTherapistScreen> createState() => _SwitchTherapistScreenState();
}

class _SwitchTherapistScreenState extends ConsumerState<SwitchTherapistScreen> {
  static const _reasons = {
    'approach': 'I want a different way of working',
    'expertise': 'I need someone with specific expertise',
    'time': "Their times don't work for me",
    'identity': "I'd be more comfortable with a different background or gender",
    'fit': "It just didn't feel right",
  };

  String? _reason;
  String? _gender;
  List<Map<String, dynamic>>? _matches;
  bool _loading = false;

  Future<void> _search() async {
    setState(() => _loading = true);
    final mine = {
      for (final t in ref.read(careTeamProvider).valueOrNull ?? const <Map<String, dynamic>>[]) t['user_id'],
    };
    try {
      final res = await ref.read(dioProvider).get<Map<String, dynamic>>('/professionals', queryParameters: {
        'sort': 'match',
        'per_page': 20,
        if (_gender != null) 'gender': _gender,
      });
      final list = ((res.data?['data'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .where((p) => !mine.contains(p['user_id']))
          .toList();
      if (mounted) setState(() => _matches = list);
    } catch (_) {
      if (mounted) setState(() => _matches = const []);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matches = _matches;
    return FriendPageScaffold(
      eyebrow: 'Your care team',
      title: 'Switch professional',
      subtitle: "It's free, and your current professional is not told why. Your past sessions and notes stay yours.",
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('What would help most?', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final r in _reasons.entries)
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: r.key,
              groupValue: _reason,
              onChanged: (v) => setState(() => _reason = v),
              title: Text(r.value),
            ),
          if (_reason == 'identity') ...[
            const SizedBox(height: 8),
            Text('I would prefer', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final g in const [(null, 'No preference'), ('female', 'A woman'), ('male', 'A man')])
                  ChoiceChip(
                    label: Text(g.$2),
                    showCheckmark: false,
                    selected: _gender == g.$1,
                    onSelected: (_) => setState(() => _gender = g.$1),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          FriendGlowButton(
            label: _loading ? 'Finding people…' : 'Show me who is available',
            expanded: true,
            onPressed: _reason == null || _loading ? null : _search,
          ),
          if (matches != null) ...[
            const SizedBox(height: 20),
            if (matches.isEmpty)
              const FriendEmptyState(
                icon: Icons.person_search_rounded,
                title: 'No one matches yet',
                message: 'Try "No preference", or browse everyone in Explore.',
              ),
            for (final p in matches)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CandyCard(
                  onTap: () => context.push('/pros/${p['id']}'),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      FriendAvatar(initials: personInitial(p['display_name'] as String?), size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${p['display_name']}', style: theme.textTheme.titleSmall),
                            Text(
                              '${(p['category'] as Map?)?['name'] ?? ''} · ${p['experience_years']} yrs',
                              style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatMoney(p['hourly_rate_cents'] as num?, p['currency'] as String?),
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
