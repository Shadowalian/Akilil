import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';

/// Family: your own date of birth (if missing), the children you book and
/// pay for, and invitations to couples / family sessions.
class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  List<Map<String, dynamic>> _children = const [];
  List<Map<String, dynamic>> _invites = const [];
  bool _needsDob = false;
  bool _loading = true;

  Dio get _dio => ref.read(dioProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await _dio.get<Map<String, dynamic>>('/me');
      final deps = await _dio.get<Map<String, dynamic>>('/dependents');
      final inv = await _dio.get<Map<String, dynamic>>('/appointment-invites');
      if (!mounted) return;
      final meData = (me.data?['data'] as Map?) ?? me.data ?? const {};
      setState(() {
        _needsDob = meData['needs_date_of_birth'] == true;
        _children = ((deps.data?['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
        _invites = ((inv.data?['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _run(Future<void> Function() action, String ok) async {
    try {
      await action();
      if (!mounted) return;
      _toast(ok);
      await _load();
    } on DioException catch (e) {
      if (mounted) _toast(apiErrorMessage(e.response?.data));
    }
  }

  Future<DateTime?> _pickDate({required bool adult}) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: DateTime(now.year - (adult ? 25 : 8)),
      firstDate: DateTime(adult ? 1900 : now.year - 18),
      lastDate: now,
      helpText: 'Date of birth',
    );
  }

  Future<void> _setMyDob() async {
    final dob = await _pickDate(adult: true);
    if (dob == null) return;
    await _run(() async {
      await _dio.put('/me', data: {'date_of_birth': dob.toIso8601String().substring(0, 10)});
      await ref.read(authControllerProvider).refreshUser();
    }, 'Saved');
  }

  Future<void> _addChild() async {
    final name = TextEditingController();
    DateTime? dob;
    var relationship = 'parent';
    var consent = false;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add a child', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(controller: name, decoration: const InputDecoration(labelText: "Child's name")),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.cake_outlined, size: 18),
                label: Text(dob == null ? 'Date of birth' : '${dob!.day}/${dob!.month}/${dob!.year}'),
                onPressed: () async {
                  final d = await _pickDate(adult: false);
                  if (d != null) setSheet(() => dob = d);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: relationship,
                decoration: const InputDecoration(labelText: 'I am their'),
                items: const [
                  DropdownMenuItem(value: 'parent', child: Text('Parent')),
                  DropdownMenuItem(value: 'legal_guardian', child: Text('Legal guardian')),
                  DropdownMenuItem(value: 'grandparent', child: Text('Grandparent')),
                  DropdownMenuItem(value: 'other_relative', child: Text('Other relative')),
                ],
                onChanged: (v) => setSheet(() => relationship = v ?? 'parent'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: consent,
                onChanged: (v) => setSheet(() => consent = v ?? false),
                title: Text(
                  'I am this child\'s parent or legal guardian and I consent to them receiving care on Akilil. I will book and pay for their sessions.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              FilledButton(
                onPressed: consent && dob != null && name.text.trim().length >= 2
                    ? () => Navigator.pop(sheet, true)
                    : null,
                child: const Text('Add child'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || dob == null) return;
    await _run(
      () => _dio.post('/dependents', data: {
        'name': name.text.trim(),
        'date_of_birth': dob!.toIso8601String().substring(0, 10),
        'relationship': relationship,
        'guardian_consent': true,
      }),
      'Child added',
    );
  }

  Future<void> _teenLogin(Map<String, dynamic> child) async {
    final email = TextEditingController();
    final pass = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Login for ${child['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('They can join sessions and message their professional. You still book and pay.'),
            TextField(controller: email, decoration: const InputDecoration(labelText: 'Their email')),
            TextField(
              controller: pass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password (8+, upper, lower, number)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok != true) return;
    await _run(
      () => _dio.post('/dependents/${child['id']}/teen-login', data: {
        'email': email.text.trim(),
        'password': pass.text,
        'password_confirmation': pass.text,
      }),
      'Login created',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FriendPageScaffold(
      eyebrow: 'Family',
      title: 'People you care for',
      subtitle: 'Book and pay for your children, and join sessions you are invited to.',
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.all(FriendLayout.horizontal),
              children: [
                if (_needsDob)
                  CandyCard(
                    tint: FriendColors.accent,
                    accentStripe: true,
                    onTap: _setMyDob,
                    child: const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.cake_outlined),
                      title: Text('Add your date of birth'),
                      subtitle: Text('Needed before you can book or pay.'),
                    ),
                  ),
                for (final i in _invites)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: CandyCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${i['invited_by']} invited you to a ${i['care_format']} session',
                            style: theme.textTheme.titleSmall,
                          ),
                          Text('with ${i['professional']}', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              FilledButton(
                                onPressed: () => _run(
                                  () => _dio.post('/appointment-invites/accept', data: {'invite_id': i['id']}),
                                  'Added to your sessions',
                                ),
                                child: const Text('Accept'),
                              ),
                              TextButton(
                                onPressed: () => _run(
                                  () => _dio.post('/appointment-invites/decline', data: {'invite_id': i['id']}),
                                  'Declined',
                                ),
                                child: const Text('Decline'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('My children', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_children.isEmpty)
                  Text(
                    'Children under 18 cannot have their own account. Add them here and you can book sessions with professionals who work with their age group.',
                    style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary),
                  ),
                for (final c in _children)
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.child_care_rounded)),
                      title: Text('${c['name']} · ${c['age']}'),
                      subtitle: Text(c['has_teen_login'] == true ? 'Has their own login' : 'Joins with you'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'login') _teenLogin(c);
                          if (v == 'revoke') {
                            _run(() => _dio.delete('/dependents/${c['id']}/teen-login'), 'Login removed');
                          }
                          if (v == 'remove') _run(() => _dio.delete('/dependents/${c['id']}'), 'Removed');
                        },
                        itemBuilder: (_) => [
                          if (c['can_have_teen_login'] == true && c['has_teen_login'] != true)
                            const PopupMenuItem(value: 'login', child: Text('Create their own login')),
                          if (c['has_teen_login'] == true)
                            const PopupMenuItem(value: 'revoke', child: Text('Remove their login')),
                          const PopupMenuItem(value: 'remove', child: Text('Remove child')),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                FriendGlowButton(label: 'Add a child', icon: Icons.add_rounded, onPressed: _addChild, expanded: true),
              ],
            ),
    );
  }
}
