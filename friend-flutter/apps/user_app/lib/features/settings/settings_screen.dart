import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/core.dart';
import '../../l10n/language_toggle.dart';
import '../auth/app_lock_controller.dart';
import 'subscription_screen.dart';
import 'switch_therapist_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _sessionReminders = true;
  bool _therapistMessages = true;
  bool _dailyCheckIn = true;
  late bool _biometricLock;

  @override
  void initState() {
    super.initState();
    _biometricLock = ref.read(appLockProvider.notifier).biometricEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return FriendPageScaffold(
      eyebrow: 'Account',
      title: 'Settings & Care',
      subtitle: 'Manage your BetterHelp counseling membership, privacy, and therapy matching preferences.',
      showBack: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Primary Counselor Match Tile
          CandyCard(
            tint: FriendColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: FriendColors.primaryLight,
                      child: Text(
                        'M',
                        style: GoogleFonts.urbanist(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: FriendColors.primaryDeep,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. Maya Lin, Psy.D.',
                            style: GoogleFonts.urbanist(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: FriendColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Primary Matched Counselor • Active',
                            style: GoogleFonts.urbanist(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: FriendColors.primaryDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SwitchTherapistScreen()),
                        ),
                        icon: const Icon(Icons.sync_rounded, size: 16),
                        label: const Text('Switch Therapist'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: FriendColors.primary,
                          side: const BorderSide(color: FriendColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(FriendRadii.pill),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                        ),
                        icon: const Icon(Icons.card_membership_rounded, size: 16),
                        label: const Text('Plan: \$65/wk'),
                        style: FilledButton.styleFrom(
                          backgroundColor: FriendColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(FriendRadii.pill),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Clinical Tools & Crisis
          _SectionHeader('Clinical Care & Safety'),
          CandyCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                FriendMenuTile(
                  icon: Icons.emergency_rounded,
                  title: 'Crisis & Safety Center',
                  subtitle: '24/7 Lifelines (988) & Safety Plan',
                  onTap: () => context.push('/crisis'),
                ),
                const Divider(height: 1, indent: 18, endIndent: 18),
                FriendMenuTile(
                  icon: Icons.edit_note_rounded,
                  title: 'CBT Worksheets & Exercises',
                  subtitle: 'Assigned thought records & somatic tools',
                  onTap: () => context.push('/worksheets'),
                ),
                const Divider(height: 1, indent: 18, endIndent: 18),
                FriendMenuTile(
                  icon: Icons.assessment_outlined,
                  title: 'Symptom Screeners (PHQ-9 & GAD-7)',
                  subtitle: 'Depression & Anxiety track scores',
                  onTap: () => context.push('/assessments'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Notifications Preferences
          _SectionHeader('Notification Preferences'),
          CandyCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Session Reminders',
                    style: GoogleFonts.urbanist(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Alert 15 minutes before scheduled video call',
                    style: GoogleFonts.urbanist(fontSize: 12, color: FriendColors.textSecondary),
                  ),
                  value: _sessionReminders,
                  activeThumbColor: FriendColors.primary,
                  onChanged: (v) => setState(() => _sessionReminders = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(
                    'Counselor Messages',
                    style: GoogleFonts.urbanist(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Notify immediately when Dr. Maya Lin replies',
                    style: GoogleFonts.urbanist(fontSize: 12, color: FriendColors.textSecondary),
                  ),
                  value: _therapistMessages,
                  activeThumbColor: FriendColors.primary,
                  onChanged: (v) => setState(() => _therapistMessages = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(
                    'Daily Mindfulness Check-in',
                    style: GoogleFonts.urbanist(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Gentle daily reminder to log mood & gratitude',
                    style: GoogleFonts.urbanist(fontSize: 12, color: FriendColors.textSecondary),
                  ),
                  value: _dailyCheckIn,
                  activeThumbColor: FriendColors.primary,
                  onChanged: (v) => setState(() => _dailyCheckIn = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Privacy & Security
          _SectionHeader('Privacy & Security'),
          CandyCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Biometric & PIN App Lock',
                    style: GoogleFonts.urbanist(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Require FaceID/Fingerprint to open private journal and chat',
                    style: GoogleFonts.urbanist(fontSize: 12, color: FriendColors.textSecondary),
                  ),
                  value: _biometricLock,
                  activeThumbColor: FriendColors.primary,
                  onChanged: (v) {
                    setState(() => _biometricLock = v);
                    ref.read(appLockProvider.notifier).setBiometricEnabled(enabled: v);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined, color: FriendColors.primary),
                  title: Text(
                    'Export Clinical Records & Journal',
                    style: GoogleFonts.urbanist(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Download encrypted PDF of your therapy worksheets & progress',
                    style: GoogleFonts.urbanist(fontSize: 12, color: FriendColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Preparing encrypted export archive...')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: FriendColors.primary),
                  title: Text(
                    'App Language',
                    style: GoogleFonts.urbanist(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  trailing: const LanguageToggle(compact: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: GoogleFonts.urbanist(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: FriendColors.textPrimary,
        ),
      ),
    );
  }
}
