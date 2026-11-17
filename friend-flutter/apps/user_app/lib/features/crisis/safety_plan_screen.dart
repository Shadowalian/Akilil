import 'package:friend_user/l10n/tr.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'safety_plan_store.dart';

/// A personal crisis safety plan (Stanley–Brown model): warning signs,
/// things I can do alone, people I can reach, and making things safer.
/// Written in calm moments, read in hard ones.
class SafetyPlanScreen extends ConsumerWidget {
  const SafetyPlanScreen({super.key});

  Future<String?> _ask(BuildContext context, String title, String hint) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (v) => Navigator.pop(d, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: Text(tr('Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: Text(tr('Add'))),
        ],
      ),
    );
  }

  Future<({String name, String phone})?> _askPerson(BuildContext context) {
    final name = TextEditingController();
    final phone = TextEditingController();
    return showDialog<({String name, String phone})>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(tr('Someone I can call')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: tr('Name')),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: tr('Phone number')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: Text(tr('Cancel'))),
          FilledButton(
            onPressed: () => Navigator.pop(d, (name: name.text.trim(), phone: phone.text.trim())),
            child: Text(tr('Add')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(safetyPlanProvider);
    final store = ref.read(safetyPlanProvider.notifier);
    final theme = Theme.of(context);

    Widget step({
      required int n,
      required String title,
      required String hint,
      required List<String> items,
      required String addTitle,
      required String addHint,
      required void Function(List<String>) save,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: CandyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StepHeader(n: n, title: title, hint: hint),
              for (final (i, item) in items.indexed)
                _Item(text: item, onRemove: () => save([...items]..removeAt(i))),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final t = await _ask(context, addTitle, addHint);
                    if (t != null && t.isNotEmpty) save([...items, t]);
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(items.isEmpty ? tr('Add the first one') : tr('Add another')),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: FriendColors.background,
      appBar: AppBar(title: Text(tr('My safety plan'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 8, FriendLayout.horizontal, 32),
        children: [
          Text(
            tr('Fill this in on a calmer day. When things get hard, you will not have to think — just follow it. '
            'The professionals you book and the Akilil safety team can read it, so they can help you if you reach out.'),
            style: theme.textTheme.bodyMedium?.copyWith(color: FriendColors.textSecondary),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: plan.stepsDone / 4, minHeight: 4, borderRadius: BorderRadius.circular(2)),
          const SizedBox(height: 4),
          Text(trx('${plan.stepsDone} of 4 steps filled in', 'ከ4 ደረጃዎች ${plan.stepsDone} ተሞልተዋል'), style: theme.textTheme.labelSmall),
          const SizedBox(height: 18),
          step(
            n: 1,
            title: tr('My warning signs'),
            hint: tr('Thoughts, moods or situations that tell me a crisis may be coming.'),
            items: plan.warningSigns,
            addTitle: tr('A warning sign'),
            addHint: tr('e.g. I stop answering calls'),
            save: (l) => store.update(plan.copyWith(warningSigns: l)),
          ),
          step(
            n: 2,
            title: tr('Things I can do on my own'),
            hint: tr('Ways to take my mind off things without contacting anyone.'),
            items: plan.coping,
            addTitle: tr('Something that helps'),
            addHint: tr('e.g. A walk around the block'),
            save: (l) => store.update(plan.copyWith(coping: l)),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: CandyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StepHeader(n: 3, title: tr('People I can reach'), hint: tr('Friends or family I can call when I need help.')),
                  for (final (i, p) in plan.people.indexed)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: FriendAvatar(initials: personInitial(p.name), size: 36),
                      title: Text(p.name),
                      subtitle: p.phone.isEmpty ? null : Text(p.phone),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (p.phone.isNotEmpty)
                            IconButton(
                              tooltip: tr('Call'),
                              icon: const Icon(Icons.call_rounded, color: FriendColors.primary),
                              onPressed: () => launchUrl(Uri.parse('tel:${p.phone}')),
                            ),
                          IconButton(
                            tooltip: tr('Remove'),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => store.update(plan.copyWith(people: [...plan.people]..removeAt(i))),
                          ),
                        ],
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        final p = await _askPerson(context);
                        if (p != null && p.name.isNotEmpty) store.update(plan.copyWith(people: [...plan.people, p]));
                      },
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: Text(tr('Add a person')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          step(
            n: 4,
            title: tr('Making things safer'),
            hint: tr('Steps to put distance between me and anything I could use to hurt myself.'),
            items: plan.environment,
            addTitle: tr('A step'),
            addHint: tr('e.g. Give my medication to my sister to keep'),
            save: (l) => store.update(plan.copyWith(environment: l)),
          ),
          Text(
            tr('If you are in danger right now, call 907 for an ambulance or 991 for police.'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.error, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.n, required this.title, required this.hint});
  final int n;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: FriendColors.primary,
            child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(hint, style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.text, required this.onRemove});
  final String text;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: FriendColors.background,
        borderRadius: BorderRadius.circular(FriendRadii.small),
      ),
      child: Row(
        children: [
          Expanded(child: Text(text)),
          IconButton(
            tooltip: tr('Remove'),
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
