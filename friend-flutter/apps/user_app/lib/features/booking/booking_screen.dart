import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:core/core.dart';

import '../../l10n/app_locale.dart';
import '../../router.dart';
import 'booking_care_section.dart';

const _ethiopicFallback = ['NotoSansEthiopic'];
const _eatTz = 'Africa/Addis_Ababa';

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
          displayName: pro['display_name'] as String? ?? 'Listener',
          categoryName: category?['name'] as String? ?? 'Listener',
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
          const SnackBar(content: Text('Add funds to your wallet')),
        );
        context.push(AppRoutes.wallet);
        return;
      }
      final data = e.response?.data;
      if (data is Map && data['code'] == 'date_of_birth_required') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add your date of birth to book a session')),
        );
        context.push(AppRoutes.family);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(data, 'Booking failed.'))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showConfirmation({required _ProSummary pro}) {
    final s = ref.read(stringsProvider);
    final when = _localStart;
    final end = when.add(Duration(minutes: _durationMinutes));
    final dateLabel = DateFormat('EEEE, MMM d').format(when);
    final timeLabel =
        '${DateFormat('h:mm a').format(when)} – ${DateFormat('h:mm a').format(end)}';

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            24 + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FriendColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.check_circle_rounded,
                  color: FriendColors.primary, size: 56),
              const SizedBox(height: 16),
              Text(
                'Session scheduled',
                style: _geist(ctx, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              _ConfirmRow(icon: Icons.person_outline_rounded, label: pro.displayName),
              const SizedBox(height: 12),
              _ConfirmRow(icon: Icons.calendar_today_outlined, label: dateLabel),
              const SizedBox(height: 12),
              _ConfirmRow(icon: Icons.schedule_rounded, label: timeLabel),
              const SizedBox(height: 20),
              FriendGlowButton(
                label: s.sessions,
                expanded: true,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final walletAsync = ref.watch(_bookingWalletProvider);
    final pro = _pro;
    final canConfirm = pro != null &&
        _timesValid &&
        !_busy &&
        _selectedSlotUtc != null &&
        _care.isValid;
    final sessionCents = _care.priceCents ?? pro?.modeRateCents(_mode) ?? 0;
    final serviceFeeCents = 0;
    final totalCents = sessionCents + serviceFeeCents;
    final totalMajor = (totalCents / 100).round();

    return Scaffold(
      backgroundColor: FriendColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 24),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      s.bookASession,
                      textAlign: TextAlign.center,
                      style: _geist(
                        context,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                if (_proLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_proLoadError != null)
                  Text(
                    _proLoadError!,
                    style: _geist(context, color: FriendColors.error),
                  )
                else if (pro != null)
                  _ProHeader(pro: pro, minutes: pro.sessionMinutes),
                const SizedBox(height: 24),
                if (_proDetail != null)
                  BookingCareSection(
                    professional: _proDetail!,
                    onChanged: (c) => setState(() => _care = c),
                  ),
                Text(
                  s.sessionSummary,
                  style: _geist(
                    context,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: FriendColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                if (pro != null)
                  _ModeRadios(
                    selected: _mode,
                    pro: pro,
                    onChanged: (m) => setState(() => _mode = m),
                    chatLabel: s.modeChat,
                    voiceLabel: s.modeVoice,
                    videoLabel: s.modeVideo,
                    priceEtb: s.priceEtb,
                  ),
                const SizedBox(height: 28),
                _MonthHeader(date: _selectedDate),
                const SizedBox(height: 12),
                _WeekStrip(
                  selected: _selectedDate,
                  onChanged: (d) {
                    setState(() => _selectedDate = d);
                    _loadSlotsForSelectedDay();
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  s.availableTimesEat,
                  style: _geist(
                    context,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (_slotsLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_daySlots.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'No open times on this day. Try another date.',
                      style: _geist(context, color: FriendColors.textSecondary),
                    ),
                  ),
                if (!_slotsLoading)
                  _TimeChips(
                    slots: _daySlots,
                    selectedUtc: _selectedSlotUtc,
                    selectedStart: _start,
                    placeholderTimes: const [],
                    onSelectSlot: _applySlot,
                    onSelectPlaceholder: (t) {
                      setState(() {
                        _selectedSlotUtc = null;
                        _start = t;
                        final endM =
                            t.hour * 60 + t.minute + (pro?.sessionMinutes ?? 50);
                        _end = TimeOfDay(
                          hour: (endM ~/ 60) % 24,
                          minute: endM % 60,
                        );
                      });
                    },
                  ),
                const SizedBox(height: 28),
                _SummaryBlock(
                  mode: _mode,
                  date: _selectedDate,
                  start: _start,
                  durationMinutes: _durationMinutes,
                  sessionCents: sessionCents,
                  serviceFeeCents: serviceFeeCents,
                  serviceFeeLabel: s.serviceFee,
                  totalLabel: s.total,
                  priceEtb: s.priceEtb,
                  modeChat: s.modeChat,
                  modeVoice: s.modeVoice,
                  modeVideo: s.modeVideo,
                ),
                const SizedBox(height: 16),
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
                      changeLabel: s.changePayment,
                      onChange: () => context.push(AppRoutes.wallet),
                    );
                  },
                ),
                const SizedBox(height: 96),
              ],
            ),
          ),
          Container(
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                child: FilledButton(
                  onPressed: canConfirm ? _book : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: FriendColors.ink,
                    foregroundColor: FriendColors.accent,
                    disabledBackgroundColor: FriendColors.border,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FriendRadii.pill),
                    ),
                  ),
                  child: Text(
                    _busy
                        ? '…'
                        : canConfirm
                            ? s.confirmAndPay(totalMajor)
                            : s.unavailable,
                    style: _geist(
                      context,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: canConfirm ? FriendColors.accent : FriendColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
    final initial =
        pro.displayName.isNotEmpty ? pro.displayName[0].toUpperCase() : '?';

    return Row(
      children: [
        FriendAvatar(
          size: 52,
          imageUrl: pro.avatarUrl,
          initials: initial,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pro.displayName,
                style: _geist(
                  context,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${pro.categoryName} · $minutes min',
                style: _geist(
                  context,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: FriendColors.textSecondary,
                ),
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
    return Column(
      children: [
        _ModeTile(
          mode: _SessionMode.chat,
          label: chatLabel,
          price: priceEtb((pro.modeRateCents(_SessionMode.chat) / 100).round()),
          selected: selected == _SessionMode.chat,
          onTap: () => onChanged(_SessionMode.chat),
        ),
        const SizedBox(height: 8),
        _ModeTile(
          mode: _SessionMode.voice,
          label: voiceLabel,
          price: priceEtb((pro.modeRateCents(_SessionMode.voice) / 100).round()),
          selected: selected == _SessionMode.voice,
          onTap: () => onChanged(_SessionMode.voice),
        ),
        const SizedBox(height: 8),
        _ModeTile(
          mode: _SessionMode.video,
          label: videoLabel,
          price: priceEtb((pro.modeRateCents(_SessionMode.video) / 100).round()),
          selected: selected == _SessionMode.video,
          primary: true,
          onTap: () => onChanged(_SessionMode.video),
        ),
      ],
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.label,
    required this.price,
    required this.selected,
    required this.onTap,
    this.primary = false,
  });

  final _SessionMode mode;
  final String label;
  final String price;
  final bool selected;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? FriendColors.accent : FriendColors.border;
    final bg = selected
        ? FriendColors.primaryLight.withValues(alpha: 0.55)
        : FriendColors.surfaceLowest;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(FriendRadii.medium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FriendRadii.medium),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FriendRadii.medium),
            border: Border.all(
              color: borderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? FriendColors.accent : FriendColors.textMuted,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: _geist(
                    context,
                    fontSize: 16,
                    fontWeight: primary ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              Text(
                price,
                style: _geist(
                  context,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: FriendColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Text(
      DateFormat('MMMM yyyy').format(date),
      style: _geist(
        context,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.selected, required this.onChanged});
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final anchor = DateTime(selected.year, selected.month, selected.day);
    final start = anchor.subtract(Duration(days: anchor.weekday % 7));
    final days = List.generate(7, (i) => start.add(Duration(days: i)));

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = days[i];
          final isSelected = d.year == selected.year &&
              d.month == selected.month &&
              d.day == selected.day;
          return InkWell(
            onTap: () => onChanged(d),
            borderRadius: BorderRadius.circular(FriendRadii.medium),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 54,
              decoration: BoxDecoration(
                color: isSelected ? FriendColors.accent : FriendColors.surfaceLowest,
                border: Border.all(
                  color: isSelected ? FriendColors.accent : FriendColors.border,
                ),
                borderRadius: BorderRadius.circular(FriendRadii.medium),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(d).toUpperCase(),
                    style: _geist(
                      context,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : FriendColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${d.day}',
                    style: _geist(
                      context,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : FriendColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimeChips extends StatelessWidget {
  const _TimeChips({
    required this.slots,
    required this.selectedUtc,
    required this.selectedStart,
    required this.placeholderTimes,
    required this.onSelectSlot,
    required this.onSelectPlaceholder,
  });

  final List<Map<String, dynamic>> slots;
  final String? selectedUtc;
  final TimeOfDay selectedStart;
  final List<TimeOfDay> placeholderTimes;
  final ValueChanged<Map<String, dynamic>> onSelectSlot;
  final ValueChanged<TimeOfDay> onSelectPlaceholder;

  @override
  Widget build(BuildContext context) {
  final hasSlots = slots.isNotEmpty;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (hasSlots)
          for (final slot in slots)
            _TimeChip(
              label: _slotLabel(slot),
              selected: slot['start_at']?.toString() == selectedUtc,
              onTap: () => onSelectSlot(slot),
            )
        else
          for (final t in placeholderTimes)
            _TimeChip(
              label: _fmt(t),
              selected: t.hour == selectedStart.hour && t.minute == selectedStart.minute,
              onTap: () => onSelectPlaceholder(t),
            ),
      ],
    );
  }

  String _slotLabel(Map<String, dynamic> slot) {
    final local = DateTime.tryParse(slot['start_local']?.toString() ?? '');
    if (local != null) return DateFormat('h:mm a').format(local);
    return '—';
  }

  String _fmt(TimeOfDay t) {
    final dt = DateTime(2000, 1, 1, t.hour, t.minute);
    return DateFormat('h:mm a').format(dt);
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FriendRadii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? FriendColors.accent : FriendColors.surfaceLowest,
          borderRadius: BorderRadius.circular(FriendRadii.pill),
          border: Border.all(
            color: selected ? FriendColors.accent : FriendColors.border,
          ),
        ),
        child: Text(
          label,
          style: _geist(
            context,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : FriendColors.textPrimary,
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
    required this.durationMinutes,
    required this.sessionCents,
    required this.serviceFeeCents,
    required this.serviceFeeLabel,
    required this.totalLabel,
    required this.priceEtb,
    required this.modeChat,
    required this.modeVoice,
    required this.modeVideo,
  });

  final _SessionMode mode;
  final DateTime date;
  final TimeOfDay start;
  final int durationMinutes;
  final int sessionCents;
  final int serviceFeeCents;
  final String serviceFeeLabel;
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
    final whenLabel =
        '${DateFormat('EEE, MMM d').format(dt)} · ${DateFormat('h:mm a').format(dt)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FriendColors.surfaceLowest,
        borderRadius: BorderRadius.circular(FriendRadii.medium),
        border: Border.all(color: FriendColors.border),
      ),
      child: Column(
        children: [
          _SummaryLine(label: modeLabel, value: '$durationMinutes min'),
          const SizedBox(height: 8),
          _SummaryLine(label: whenLabel, value: priceEtb((sessionCents / 100).round())),
          const SizedBox(height: 8),
          _SummaryLine(
            label: serviceFeeLabel,
            value: priceEtb((serviceFeeCents / 100).round()),
          ),
          const Divider(height: 24),
          _SummaryLine(
            label: totalLabel,
            value: priceEtb(((sessionCents + serviceFeeCents) / 100).round()),
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: _geist(
              context,
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: FriendColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: _geist(
            context,
            fontSize: 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
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
  });

  final String title;
  final String balanceLabel;
  final String balance;
  final String changeLabel;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FriendColors.recessed,
        borderRadius: BorderRadius.circular(FriendRadii.medium),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined,
              color: FriendColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _geist(context, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Text(
                  '$balanceLabel: $balance',
                  style: _geist(
                    context,
                    fontSize: 13,
                    color: FriendColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: Text(
              changeLabel,
              style: _geist(
                context,
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

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: FriendColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: _geist(context, fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}