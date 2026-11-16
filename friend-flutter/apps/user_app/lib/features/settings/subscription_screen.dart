import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/core.dart';
import '../core_data/seed_data.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _selectedPlanId = 'plan-weekly';

  void _confirmPlan(Map<String, dynamic> plan) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() {
      _selectedPlanId = plan['id'] as String;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: FriendColors.primaryDeep,
        content: Text(
          'Your membership has been updated to ${plan['name']}!',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans = SeedData.subscriptionPlans;

    return FriendPageScaffold(
      eyebrow: 'Membership',
      title: 'Therapy Plans & Billing',
      subtitle:
          'Transparent BetterHelp-style therapy subscriptions. Cancel or pause anytime with no hidden lock-in.',
      showBack: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current Active Plan Status Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A9FC4), Color(0xFF0F7FA0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(FriendRadii.card),
              boxShadow: FriendElevation.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(FriendRadii.pill),
                      ),
                      child: Text(
                        'ACTIVE MEMBERSHIP',
                        style: GoogleFonts.urbanist(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Weekly Therapy Plan',
                  style: GoogleFonts.urbanist(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Next auto-renewal: in 24 days (\$260.00/mo billed via Visa ending in 4242)',
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Matched with Dr. Maya Lin, Psy.D.',
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Available Subscription Tiers',
            style: GoogleFonts.urbanist(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: FriendColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          for (final plan in plans) ...[
            _PlanCard(
              plan: plan,
              isCurrent: _selectedPlanId == plan['id'],
              onSelect: () => _confirmPlan(plan),
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 24),

          // Financial Aid & Sliding Scale Banner
          CandyCard(
            tint: FriendColors.green,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: FriendColors.greenSoft,
                    borderRadius: BorderRadius.circular(FriendRadii.small),
                  ),
                  child: const Icon(Icons.volunteer_activism_rounded, color: FriendColors.primaryDeep),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Financial Aid Available',
                        style: GoogleFonts.urbanist(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: FriendColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'We offer income-based assistance to ensure mental health support is never out of reach.',
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          color: FriendColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Financial assistance application opened.')),
                    );
                  },
                  child: Text(
                    'Apply',
                    style: GoogleFonts.urbanist(fontWeight: FontWeight.w800, color: FriendColors.primary),
                  ),
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.onSelect,
  });

  final Map<String, dynamic> plan;
  final bool isCurrent;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final name = plan['name'] as String? ?? '';
    final price = plan['price_display'] as String? ?? '';
    final cadence = plan['cadence'] as String? ?? '';
    final features = (plan['features'] as List?)?.cast<String>() ?? [];
    final isPopular = plan['is_popular'] == true;

    return CandyCard(
      tint: isCurrent ? FriendColors.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPopular)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: FriendColors.primaryLight,
                          borderRadius: BorderRadius.circular(FriendRadii.pill),
                        ),
                        child: Text(
                          'MOST POPULAR',
                          style: GoogleFonts.urbanist(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: FriendColors.primaryDeep,
                          ),
                        ),
                      ),
                    Text(
                      name,
                      style: GoogleFonts.urbanist(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: FriendColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: GoogleFonts.urbanist(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: FriendColors.primaryDeep,
                    ),
                  ),
                  Text(
                    cadence,
                    style: GoogleFonts.urbanist(
                      fontSize: 11,
                      color: FriendColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          for (final f in features) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_rounded, size: 16, color: FriendColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        color: FriendColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (isCurrent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: FriendColors.greenSoft,
                borderRadius: BorderRadius.circular(FriendRadii.pill),
              ),
              child: Center(
                child: Text(
                  'Current Plan Active',
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: FriendColors.primaryDeep,
                  ),
                ),
              ),
            )
          else
            OutlinedButton(
              onPressed: onSelect,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(FriendRadii.pill),
                ),
                side: const BorderSide(color: FriendColors.primary),
              ),
              child: Text(
                'Switch to this Plan',
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: FriendColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
