import 'package:intl/intl.dart';
import 'package:friend_user/l10n/tr.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';
import '../../router.dart';
import 'booking_care_section.dart';

const _eatTz = 'Africa/Addis_Ababa';


final _bookingWalletProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ref.read(dioProvider).get<Map<String, dynamic>>('/me/wallet');
  return res.data ?? const <String, dynamic>{};
});

enum _SessionMode { chat, voice, video }

/// C08 — Book a session (mode, calendar, slots, wallet, confirm).
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.proId});
  final String proId;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _ProSummary {
  const _ProSummary({
    required this.userId,
    required this.displayName,
    required this.categoryName,
    required this.sessionMinutes,
    required this.avatarUrl,
    required this.hourlyRateCents,
    required this.currency,
    required this.chatRateCents,
    required this.voiceRateCents,
    required this.videoRateCents,
  });

  final int userId;
  final String displayName;
  final String categoryName;
  final int sessionMinutes;
  final String? avatarUrl;
  final int hourlyRateCents;
  final String currency;
  final int? chatRateCents;
  final int? voiceRateCents;
  final int? videoRateCents;

  /// What the server charges for a session. It is one flat price per
  /// session (per care format), whatever the mode — show exactly that.
  int modeRateCents(_SessionMode mode) => hourlyRateCents;
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  TimeOfDay _start = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 50);
  _SessionMode _mode = _SessionMode.video;
  String? _selectedSlotUtc;
  bool _busy = false;

  _ProSummary? _pro;
  Map<String, dynamic>? _proDetail;
  BookingCareSelection _care = const BookingCareSelection();
  String? _proLoadError;
  bool _proLoading = true;

  List<Map<String, dynamic>> _daySlots = const [];
  bool _slotsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfessional();
  }

  Future<void> _loadProfessional() async {
    try {
      final dio = ref.read(dioProvider);
      final res =
          await dio.get<Map<String, dynamic>>('/professionals/${widget.proId}');
      final body = res.data ?? const <String, dynamic>{};
      final pro = (body['data'] as Map<String, dynamic>?) ?? body;
      final userId = (pro['user_id'] as num?)?.toInt();
      if (!mounted) return;
      if (userId == null) {
        setState(() {
          _proLoading = false;
          _proLoadError = "Couldn't load this listener.";
        });
        return;
      }
      final category = pro['category'] as Map<String, dynamic>?;
      final minutes = (pro['session_duration_minutes'] as num?)?.toInt() ?? 50;
      final hourly = (pro['hourly_rate_cents'] as num?)?.toInt() ?? 0;
      setState(() {
        _proLoading = false;
        _proDetail = pro;
        _pro = _ProSummary(
          userId: userId,
          displayName: pro['display_name'] as String? ?? tr('Listener'),
          categoryName: tr(category?['name'] as String? ?? 'Listener'),
          sessionMinutes: minutes,
          avatarUrl: pro['avatar_url'] as String?,
          hourlyRateCents: hourly,
          currency: pro['currency'] as String? ?? 'ETB',
          chatRateCents: (pro['chat_rate_cents'] as num?)?.toInt(),
          voiceRateCents: (pro['voice_rate_cents'] as num?)?.toInt(),
          videoRateCents: (pro['video_rate_cents'] as num?)?.toInt(),
        );
        final endM = 10 * 60 + minutes;
        _end = TimeOfDay(hour: endM ~/ 60, minute: endM % 60);
      });
      await _loadSlotsForSelectedDay();
    } on DioException {
      if (!mounted) return;
      setState(() {
        _proLoading = false;
        _proLoadError = "Couldn't load this listener.";
      });
    }
  }

  Future<void> _loadSlotsForSelectedDay() async {
    setState(() {
      _slotsLoading = true;
      _selectedSlotUtc = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final duration = _pro?.sessionMinutes ?? 50;
      final res = await dio.get<Map<String, dynamic>>(
        '/professionals/${widget.proId}/available-slots',
        queryParameters: {
          'date': dateStr,
          'timezone': _eatTz,
          'duration_minutes': duration,
        },
      );
      final slots = ((res.data?['slots'] as List?) ?? const [])
          .cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _daySlots = slots;
        _slotsLoading = false;
      });
      if (slots.isNotEmpty) {
        _applySlot(slots.first);
      } else {
        _applyPlaceholderTimes();
      }
    } on DioException {
      if (!mounted) return;
      setState(() {
        _slotsLoading = false;
        _daySlots = const [];
      });
      _applyPlaceholderTimes();
    }
  }

  void _applyPlaceholderTimes() {
    const placeholders = [
      (10, 0),
      (14, 0),
      (16, 30),
      (18, 0),
    ];
    if (!mounted) return;
    final first = placeholders.first;
    setState(() {
      _start = TimeOfDay(hour: first.$1, minute: first.$2);
      final endM = first.$1 * 60 + first.$2 + (_pro?.sessionMinutes ?? 50);
      _end = TimeOfDay(hour: (endM ~/ 60) % 24, minute: endM % 60);
    });
  }

  void _applySlot(Map<String, dynamic> slot) {
    final utc = slot['start_at']?.toString();
    final local = DateTime.tryParse(slot['start_local']?.toString() ?? '') ??
        DateTime.tryParse(utc ?? '');
    final duration = (slot['duration_minutes'] as num?)?.toInt() ??
        _pro?.sessionMinutes ??
        50;
    if (local == null) return;
    setState(() {
      _selectedSlotUtc = utc;
      _start = TimeOfDay(hour: local.hour, minute: local.minute);
      final endM = local.hour * 60 + local.minute + duration;
      _end = TimeOfDay(hour: (endM ~/ 60) % 24, minute: endM % 60);
    });
  }

  int get _durationMinutes {
    final startM = _start.hour * 60 + _start.minute;
    final endM = _end.hour * 60 + _end.minute;
    return endM - startM;
  }

  bool get _timesValid => _durationMinutes >= 15 && _durationMinutes <= 240;

  DateTime get _localStart => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _start.hour,
        _start.minute,
      );

  String get _sessionType => switch (_mode) {
        _SessionMode.chat => 'chat',
        _SessionMode.voice => 'voice',
        _SessionMode.video => 'video',
      };

  Future<void> _book() async {
    final pro = _pro;
    // Only a slot the server offered can be booked: send its exact instant.
    final scheduledAt = _selectedSlotUtc;
    if (pro == null || !_timesValid || scheduledAt == null || !_care.isValid) return;
    setState(() => _busy = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/appointments', data: {
        'professional_user_id': pro.userId,
        'scheduled_at': scheduledAt,
        'duration_minutes': _durationMinutes,
        'session_type': _sessionType,
        'user_timezone': _eatTz,
        ..._care.toPayload(),
      });
      if (!mounted) return;
      await _showConfirmation(pro: pro);
      if (!mounted) return;
      context.go('/appointments');
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 402) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Add funds to your wallet'))),
        );
        context.push(AppRoutes.wallet);
        return;
      }
      final data = e.response?.data;
      if (data is Map && data['code'] == 'date_of_birth_required') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Add your date of birth to book a session'))),
        );
        context.push(AppRoutes.family);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(data, tr('Booking failed.')))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showConfirmation({required _ProSummary pro}) {
    final when = _localStart;
    final end = when.add(Duration(minutes: _durationMinutes));
    final dateLabel = trDate('EEEE, MMM d', when);
    final timeLabel =
        '${trDate('h:mm a', when)} – ${trDate('h:mm a', end)}';

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: FriendColors.successLight, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: FriendColors.success, size: 28),
                ),
                const SizedBox(height: 16),
                Text(tr('Session scheduled'), style: theme.textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  tr('We will remind you before it starts. You can join from Sessions.'),
                  style: theme.textTheme.bodyMedium?.copyWith(color: FriendColors.textSecondary),
                ),
                const SizedBox(height: 20),
                FriendListGroup(
                  dividerIndent: 52,
                  children: [
                    _ConfirmRow(icon: Icons.person_outline_rounded, label: pro.displayName),
                    _ConfirmRow(icon: Icons.calendar_today_outlined, label: dateLabel),
                    _ConfirmRow(icon: Icons.schedule_rounded, label: timeLabel),
                  ],
                ),
                const SizedBox(height: 20),
                FriendGlowButton(label: tr('Done'), expanded: true, onPressed: () => Navigator.of(ctx).pop()),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final walletAsync = ref.watch(_bookingWalletProvider);
    final pro = _pro;
    final canConfirm = pro != null && _timesValid && !_busy && _selectedSlotUtc != null && _care.isValid;
    final sessionCents = _care.priceCents ?? pro?.modeRateCents(_mode) ?? 0;
    final totalMajor = (sessionCents / 100).round();

    return Scaffold(
      backgroundColor: FriendColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FriendContentWidth(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    FriendBackButton(onPressed: () => context.pop()),
                    const SizedBox(width: 12),
                    Expanded(child: Text(s.bookASession, style: theme.textTheme.titleMedium)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FriendContentWidth(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 20, FriendLayout.horizontal, 32),
                  children: [
                    if (_proLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
                      )
                    else if (_proLoadError != null)
                      Text(_proLoadError!, style: theme.textTheme.bodyMedium?.copyWith(color: FriendColors.error))
                    else if (pro != null)
                      _ProHeader(pro: pro, minutes: pro.sessionMinutes),
                    const SizedBox(height: FriendLayout.sectionGap),
                    if (_proDetail != null)
                      BookingCareSection(professional: _proDetail!, onChanged: (c) => setState(() => _care = c)),
                    if (pro != null) ...[
                      FriendSectionLabel(tr('How would you like to meet?')),
                      _ModeRadios(
                        selected: _mode,
                        pro: pro,
                        onChanged: (m) => setState(() => _mode = m),
                        chatLabel: s.modeChat,
                        voiceLabel: s.modeVoice,
                        videoLabel: s.modeVideo,
                        priceEtb: s.priceEtb,
                      ),
                    ],
                    const SizedBox(height: FriendLayout.sectionGap),
                    FriendSectionLabel(trDate('MMMM y', _selectedDate)),
                    _DayStrip(
                      selected: _selectedDate,
                      onChanged: (d) {
                        setState(() {
                          _selectedDate = d;
                          _selectedSlotUtc = null;
                        });
                        _loadSlotsForSelectedDay();
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: Text(s.availableTimesEat, style: theme.textTheme.titleSmall)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_slotsLoading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                      )
                    else if (_daySlots.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: FriendColors.recessed,
                          borderRadius: BorderRadius.circular(FriendRadii.medium),
                        ),
                        child: Text(
                          tr('No open times on this day. Try another date.'),
                          style: theme.textTheme.bodySmall,
                        ),
                      )
                    else
                      _TimeChips(slots: _daySlots, selectedUtc: _selectedSlotUtc, onSelectSlot: _applySlot),
                    const SizedBox(height: FriendLayout.sectionGap),
                    FriendSectionLabel(s.sessionSummary),
                    _SummaryBlock(
                      mode: _mode,
                      date: _selectedDate,
                      start: _start,
                      hasTime: _selectedSlotUtc != null,
                      durationMinutes: _durationMinutes,
                      sessionCents: sessionCents,
                      totalLabel: s.total,
                      priceEtb: s.priceEtb,
                      modeChat: s.modeChat,
                      modeVoice: s.modeVoice,
                      modeVideo: s.modeVideo,
                    ),
                    const SizedBox(height: 12),
                    walletAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (error, stackTrace) => const SizedBox.shrink(),
                      data: (w) {
                        final cents = (w['balance_cents'] as num?)?.toInt() ?? 0;
                        final cur = w['currency'] as String? ?? 'ETB';
                        final bal = (cents / 100).round();
                        return _WalletRow(
                          title: s.akililWallet,
                          balanceLabel: s.walletBalance,
                          balance: cur == 'ETB' ? s.priceEtb(bal) : '$bal $cur',
                          low: cents < sessionCents,
                          changeLabel: cents < sessionCents ? tr('Top up') : s.changePayment,
                          onChange: () => context.push(AppRoutes.wallet),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: FriendColors.surface,
                border: Border(top: BorderSide(color: FriendColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: FriendContentWidth(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 12, FriendLayout.horizontal, 12),
                    child: FriendGlowButton(
                      expanded: true,
                      busy: _busy,
                      onPressed: canConfirm ? _book : null,
                      label: canConfirm
                          ? s.confirmAndPay(totalMajor)
                          : _care.problem ?? (_selectedSlotUtc == null ? tr('Pick a time') : s.unavailable),
                    ),
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

class _ProHeader extends StatelessWidget {
  const _ProHeader({required this.pro, required this.minutes});

  final _ProSummary pro;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        FriendAvatar(size: 52, imageUrl: pro.avatarUrl, initials: personInitial(pro.displayName)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pro.displayName, style: theme.textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                trx('${pro.categoryName} · $minutes min', '${pro.categoryName} · $minutes ደቂቃ'),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeRadios extends StatelessWidget {
  const _ModeRadios({
    required this.selected,
    required this.pro,
    required this.onChanged,
    required this.chatLabel,
    required this.voiceLabel,
    required this.videoLabel,
    required this.priceEtb,
  });

  final _SessionMode selected;
  final _ProSummary pro;
  final ValueChanged<_SessionMode> onChanged;
  final String chatLabel;
  final String voiceLabel;
  final String videoLabel;
  final String Function(int) priceEtb;

  @override
  Widget build(BuildContext context) {
    final modes = [
      (_SessionMode.video, videoLabel, Icons.videocam_outlined),
      (_SessionMode.voice, voiceLabel, Icons.call_outlined),
      (_SessionMode.chat, chatLabel, Icons.chat_bubble_outline_rounded),
    ];
    return Column(
      children: [
        for (final (mode, label, icon) in modes) ...[
          FriendPhqOptionWithIcon(
            icon: icon,
            label: label,
            trailing: priceEtb((pro.modeRateCents(mode) / 100).round()),
            selected: selected == mode,
            onTap: () => onChanged(mode),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Selectable row with an icon and a value on the right.
class FriendPhqOptionWithIcon extends StatelessWidget {
  const FriendPhqOptionWithIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.trailing,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String trailing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(FriendRadii.medium);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? FriendColors.primaryLight : FriendColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: selected ? FriendColors.primary : FriendColors.border, width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: selected ? FriendColors.primary : FriendColors.textSecondary),
                const SizedBox(width: 14),
                Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
                Text(trailing, style: theme.textTheme.labelMedium?.copyWith(fontFeatures: friendTabular)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The next three weeks, starting today.
class _DayStrip extends StatefulWidget {
  const _DayStrip({required this.selected, required this.onChanged});

  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  @override
  State<_DayStrip> createState() => _DayStripState();
}

class _DayStripState extends State<_DayStrip> {
  late final DateTime _today = () {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = List.generate(21, (i) => _today.add(Duration(days: i)));
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: days.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = days[i];
          final sel = DateUtils.isSameDay(d, widget.selected);
          return Semantics(
            selected: sel,
            button: true,
            label: trDate('EEEE d MMMM', d),
            excludeSemantics: true,
            child: Material(
              color: sel ? FriendColors.ink : FriendColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FriendRadii.medium),
                side: BorderSide(color: sel ? FriendColors.ink : FriendColors.border),
              ),
              child: InkWell(
                onTap: () => widget.onChanged(d),
                borderRadius: BorderRadius.circular(FriendRadii.medium),
                child: SizedBox(
                  width: 52,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        i == 0 ? tr('Today') : trDate('EEE', d),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(color: sel ? Colors.white70 : FriendColors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${d.day}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: sel ? Colors.white : FriendColors.textPrimary,
                          fontFeatures: friendTabular,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimeChips extends StatelessWidget {
  const _TimeChips({required this.slots, required this.selectedUtc, required this.onSelectSlot});

  final List<Map<String, dynamic>> slots;
  final String? selectedUtc;
  final ValueChanged<Map<String, dynamic>> onSelectSlot;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 8.0;
        final w = (c.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final slot in slots)
              SizedBox(
                width: w,
                child: _TimeChip(
                  label: _slotLabel(slot),
                  selected: slot['start_at']?.toString() == selectedUtc,
                  onTap: () => onSelectSlot(slot),
                ),
              ),
          ],
        );
      },
    );
  }

  String _slotLabel(Map<String, dynamic> slot) {
    final local = DateTime.tryParse(slot['start_local']?.toString() ?? '');
    return local != null ? trDate('h:mm a', local) : '—';
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? FriendColors.ink : FriendColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FriendRadii.medium),
          side: BorderSide(color: selected ? FriendColors.ink : FriendColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FriendRadii.medium),
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? Colors.white : FriendColors.textPrimary,
                      fontFeatures: friendTabular,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({
    required this.mode,
    required this.date,
    required this.start,
    required this.hasTime,
    required this.durationMinutes,
    required this.sessionCents,
    required this.totalLabel,
    required this.priceEtb,
    required this.modeChat,
    required this.modeVoice,
    required this.modeVideo,
  });

  final _SessionMode mode;
  final DateTime date;
  final TimeOfDay start;
  final bool hasTime;
  final int durationMinutes;
  final int sessionCents;
  final String totalLabel;
  final String Function(int) priceEtb;
  final String modeChat;
  final String modeVoice;
  final String modeVideo;

  @override
  Widget build(BuildContext context) {
    final modeLabel = switch (mode) {
      _SessionMode.chat => modeChat,
      _SessionMode.voice => modeVoice,
      _SessionMode.video => modeVideo,
    };
    final dt = DateTime(date.year, date.month, date.day, start.hour, start.minute);
    final whenLabel = hasTime ? '${trDate('EEE d MMM', dt)} · ${trDate('h:mm a', dt)}' : trDate('EEE d MMM', dt);

    return CandyCard(
      child: Column(
        children: [
          _SummaryLine(label: modeLabel, value: trx('$durationMinutes min', '$durationMinutes ደቂቃ')),
          const SizedBox(height: 10),
          _SummaryLine(label: tr('When'), value: whenLabel),
          const Divider(height: 28),
          _SummaryLine(label: totalLabel, value: priceEtb((sessionCents / 100).round()), bold: true),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: bold ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium?.copyWith(color: FriendColors.textSecondary),
          ),
        ),
        Text(
          value,
          style: (bold ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium)?.copyWith(fontFeatures: friendTabular),
        ),
      ],
    );
  }
}

class _WalletRow extends StatelessWidget {
  const _WalletRow({
    required this.title,
    required this.balanceLabel,
    required this.balance,
    required this.changeLabel,
    required this.onChange,
    this.low = false,
  });

  final String title;
  final String balanceLabel;
  final String balance;
  final String changeLabel;
  final VoidCallback onChange;
  final bool low;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CandyCard(
      tint: low ? FriendColors.warning : null,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: low ? FriendColors.warning : FriendColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(
                  low ? tr('Not enough in your wallet for this session.') : '$balanceLabel: $balance',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(onPressed: onChange, child: Text(changeLabel)),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: FriendColors.textSecondary),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
