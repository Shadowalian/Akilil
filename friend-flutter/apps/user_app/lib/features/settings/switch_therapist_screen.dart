import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/core.dart';
import '../core_data/seed_data.dart';

class SwitchTherapistScreen extends StatefulWidget {
  const SwitchTherapistScreen({super.key});

  @override
  State<SwitchTherapistScreen> createState() => _SwitchTherapistScreenState();
}

class _SwitchTherapistScreenState extends State<SwitchTherapistScreen> {
  String? _selectedReason;
  String _preferredGender = 'No preference';
  bool _searchingMatches = false;
  bool _rematched = false;
  Map<String, dynamic>? _newMatchedTherapist;

  final List<String> _reasons = [
    'Looking for a different clinical approach (e.g. more somatic or structured CBT)',
    'Seeking specialized expertise (Trauma/EMDR, Couples, Grief, ADHD)',
    'Scheduling / timezone availability conflicts',
    'Would feel more comfortable with a different background or gender',
    'Just didn’t feel the right personal connection (no hard feelings)',
  ];

  void _requestRematch() async {
    if (_selectedReason == null) return;
    setState(() => _searchingMatches = true);

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // Pick a high-match alternative therapist from seed data
    final alternatives = SeedData.professionals.where((p) => p['id'] != 'pro-maya-lin').toList();
    final newMatch = alternatives.isNotEmpty ? alternatives.first : SeedData.professionals.last;

    setState(() {
      _searchingMatches = false;
      _rematched = true;
      _newMatchedTherapist = newMatch;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FriendPageScaffold(
      eyebrow: 'Counselor Alignment',
      title: 'Switch Therapist',
      subtitle:
          'Therapy is personal. If Dr. Maya Lin isn’t the exact right fit, we will match you with another licensed professional with zero awkwardness.',
      showBack: true,
      body: _rematched && _newMatchedTherapist != null
          ? _buildSuccessView()
          : _buildFormView(),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Assurance Callout
        CandyCard(
          tint: FriendColors.primary,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.favorite_outline_rounded, color: FriendColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your current counselor will not be notified of your specific feedback or reasons. Your comfort and progress always come first.',
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: FriendColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'What is the primary reason for switching?',
          style: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: FriendColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        for (final r in _reasons) ...[
          InkWell(
            onTap: () => setState(() => _selectedReason = r),
            borderRadius: BorderRadius.circular(FriendRadii.small),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: FriendColors.surface,
                borderRadius: BorderRadius.circular(FriendRadii.small),
                border: Border.all(
                  color: _selectedReason == r ? FriendColors.primary : FriendColors.border,
                  width: _selectedReason == r ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: r,
                    groupValue: _selectedReason,
                    activeColor: FriendColors.primary,
                    onChanged: (val) => setState(() => _selectedReason = val),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r,
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: _selectedReason == r ? FontWeight.w700 : FontWeight.w500,
                        color: FriendColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),

        Text(
          'Therapist Gender Preference for New Match',
          style: GoogleFonts.urbanist(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: FriendColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: ['No preference', 'Female', 'Male', 'Non-binary'].map((g) {
            final isSel = _preferredGender == g;
            return ChoiceChip(
              label: Text(g),
              selected: isSel,
              onSelected: (val) {
                if (val) setState(() => _preferredGender = g);
              },
              selectedColor: FriendColors.primaryLight,
              backgroundColor: FriendColors.surface,
              labelStyle: GoogleFonts.urbanist(
                fontSize: 13,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                color: isSel ? FriendColors.primaryDeep : FriendColors.textPrimary,
              ),
              side: BorderSide(
                color: isSel ? FriendColors.primary : FriendColors.border,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),

        FriendGlowButton(
          label: _searchingMatches ? 'Matching New Counselor...' : 'Find My New Match',
          icon: Icons.sync_rounded,
          onPressed: _selectedReason == null || _searchingMatches ? null : _requestRematch,
        ),
        const SizedBox(height: 36),
      ],
    );
  }

  Widget _buildSuccessView() {
    final pro = _newMatchedTherapist!;
    final name = pro['name'] as String;
    final title = pro['title'] as String;
    final specialties = (pro['specialties'] as List).cast<String>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: FriendColors.surface,
            borderRadius: BorderRadius.circular(FriendRadii.card),
            border: Border.all(color: FriendColors.primary, width: 2),
            boxShadow: FriendElevation.card,
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: FriendColors.greenSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: FriendColors.primaryDeep, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'New Match Found!',
                style: GoogleFonts.urbanist(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: FriendColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Based on your preference for ${pro['category'] == 'psychiatry' ? 'trauma recovery & specialized care' : 'evidence-based counseling'}, we have matched you with:',
                textAlign: TextAlign.center,
                style: GoogleFonts.urbanist(
                  fontSize: 13,
                  color: FriendColors.textSecondary,
                ),
              ),
              const Divider(height: 28),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: FriendColors.primaryLight,
                    child: Text(
                      name[0],
                      style: GoogleFonts.urbanist(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: FriendColors.primaryDeep,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.urbanist(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: FriendColors.textPrimary,
                          ),
                        ),
                        Text(
                          title,
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: FriendColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: specialties.map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: FriendColors.background,
                      borderRadius: BorderRadius.circular(FriendRadii.pill),
                      border: Border.all(color: FriendColors.border),
                    ),
                    child: Text(
                      s,
                      style: GoogleFonts.urbanist(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        FriendGlowButton(
          label: 'Confirm & Open New Counseling Room',
          icon: Icons.chat_rounded,
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Transferred to $name. Welcome!')),
            );
          },
        ),
      ],
    );
  }
}
