import 'package:flutter/material.dart';

import '../jitsi/jitsi_session_view.dart';
import '../theme/design_tokens.dart';
import '../util/money.dart';
import 'gift_effects.dart';
import 'live_feed_controller.dart';
import 'live_models.dart';

/// A complete live-broadcast screen body: the video room with the Akilil
/// live chrome on top — host header, viewer count, scrolling comments,
/// composer, like button, gift tray and gift effects.
///
/// Used by both apps: viewers get the composer and gift tray, the host
/// gets takings, moderation on long-press, and an End button.
class LiveRoomView extends StatefulWidget {
  const LiveRoomView({
    super.key,
    required this.controller,
    required this.roomUrl,
    required this.isHost,
    required this.hostName,
    required this.title,
    this.jwt,
    this.displayName,
    this.gifts = const [],
    this.canSendGifts = false,
    this.giftsDisabledReason,
    this.currency,
    this.onClose,
    this.onEnd,
    this.onTopUp,
    this.onRemoveComment,
    this.onRemoveViewer,
    this.onToggleComments,
    this.onToggleGifts,
    this.recipeTitle,
    this.onOpenRecipe,
  });

  final LiveFeedController controller;
  final String roomUrl;
  final String? jwt;
  final String? displayName;
  final bool isHost;
  final String hostName;
  final String title;

  final List<LiveGift> gifts;
  final bool canSendGifts;

  /// Shown instead of the tray when this viewer may not send gifts.
  final String? giftsDisabledReason;
  final String? currency;

  /// Viewer leaves / host minimises.
  final VoidCallback? onClose;

  /// Host ends the broadcast for everyone.
  final VoidCallback? onEnd;
  final VoidCallback? onTopUp;

  // Host moderation.
  final void Function(LiveFeedItem item)? onRemoveComment;
  final void Function(LiveFeedItem item)? onRemoveViewer;
  final ValueChanged<bool>? onToggleComments;
  final ValueChanged<bool>? onToggleGifts;

  /// Cooking broadcasts: a chip that opens the recipe / shopping list.
  final String? recipeTitle;
  final VoidCallback? onOpenRecipe;

  @override
  State<LiveRoomView> createState() => _LiveRoomViewState();
}

class _LiveRoomViewState extends State<LiveRoomView> {
  final _hearts = LikeHeartsController();
  final _text = TextEditingController();
  final _scroll = ScrollController();
  int _lastCount = 0;
  bool _sending = false;

  LiveFeedController get _feed => widget.controller;

  @override
  void initState() {
    super.initState();
    _feed.addListener(_onFeed);
  }

  @override
  void didUpdateWidget(LiveRoomView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onFeed);
      widget.controller.addListener(_onFeed);
    }
  }

  void _onFeed() {
    if (!mounted) return;
    final count = _feed.items.length;
    if (count != _lastCount) {
      _lastCount = count;
      // Keep the newest comment in view.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        }
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    _feed.removeListener(_onFeed);
    _hearts.dispose();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    _text.clear();
    final error = await _feed.sendComment(body);
    if (!mounted) return;
    setState(() => _sending = false);
    if (error != null) _toast(error);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  void _like() {
    _hearts.pop();
    _feed.tapLike();
  }

  Future<void> _openGiftTray() async {
    if (!widget.canSendGifts || !_feed.state.allowGifts) {
      _toast(!_feed.state.allowGifts
          ? 'The host has turned gifts off.'
          : widget.giftsDisabledReason ?? 'Gifts are not available.');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => GiftTray(
        gifts: widget.gifts,
        currency: widget.currency,
        hostName: widget.hostName,
        onTopUp: widget.onTopUp,
        onSend: (gift, quantity) => _feed.sendGift(gift, quantity: quantity),
      ),
    );
  }

  void _showModeration(LiveFeedItem item) {
    if (!widget.isHost || !item.isComment) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(item.userName ?? 'Viewer'),
              subtitle: Text(item.body ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Remove this comment'),
              onTap: () {
                Navigator.pop(sheet);
                widget.onRemoveComment?.call(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: FriendColors.error),
              title: const Text('Remove viewer from broadcast'),
              onTap: () {
                Navigator.pop(sheet);
                widget.onRemoveViewer?.call(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHostSettings() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => StatefulBuilder(
        builder: (context, setSheet) {
          final state = _feed.state;
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Comments'),
                  value: state.allowComments,
                  onChanged: (v) {
                    widget.onToggleComments?.call(v);
                    Navigator.pop(sheet);
                  },
                ),
                SwitchListTile(
                  title: const Text('Gifts'),
                  value: state.allowGifts,
                  onChanged: (v) {
                    widget.onToggleGifts?.call(v);
                    Navigator.pop(sheet);
                  },
                ),
                const ListTile(
                  dense: true,
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('Long-press a comment to remove it or its author.'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return JitsiSessionView(
      roomUrl: widget.roomUrl,
      jwt: widget.jwt,
      displayName: widget.displayName,
      mode: widget.isHost ? JitsiRoomMode.broadcastHost : JitsiRoomMode.broadcastView,
      showChrome: false,
      onLeave: widget.onClose,
      overlay: _overlay(context),
    );
  }

  Widget _overlay(BuildContext context) {
    final state = _feed.state;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    // The host keeps Jitsi's own toolbar (mic / camera / flip) clear.
    final bottomReserve = widget.isHost ? 92.0 : 0.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Legibility scrims; the middle of the video stays untouched.
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.18, 0.55, 1],
                colors: [Color(0x99000000), Color(0x00000000), Color(0x00000000), Color(0xB3000000)],
              ),
            ),
          ),
        ),

        // Viewers: double-tap anywhere to like.
        if (!widget.isHost)
          Positioned.fill(
            child: GestureDetector(behavior: HitTestBehavior.translucent, onDoubleTap: _like),
          ),

        LikeHeartsLayer(controller: _hearts, remoteLikes: _feed.likes),
        GiftEffectsLayer(gifts: _feed.gifts),

        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 10 + keyboard + bottomReserve),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(state),
                if (widget.recipeTitle != null) ...[
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerLeft, child: _recipeChip()),
                ],
                const Spacer(),
                _comments(context),
                const SizedBox(height: 8),
                if (!widget.isHost) _composer(state),
              ],
            ),
          ),
        ),

        if (state.isOver || _feed.removed) _endedCurtain(),
      ],
    );
  }

  Widget _header(LiveRoomState state) {
    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(40)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: FriendColors.primary,
                  child: Text(
                    widget.hostName.isEmpty ? 'A' : widget.hostName.characters.first.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.hostName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _pill(
          color: const Color(0xFFE0563B),
          child: const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.6)),
        ),
        const SizedBox(width: 6),
        _pill(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.visibility_rounded, size: 13, color: Colors.white),
              const SizedBox(width: 4),
              Text('${state.viewerCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
        ),
        if (widget.isHost && state.giftsTotalCents != null) ...[
          const SizedBox(width: 6),
          _pill(
            color: const Color(0xCCD9924A),
            child: Text(
              '🎁 ${formatMoney(state.giftsTotalCents, widget.currency)}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
        const Spacer(),
        if (widget.isHost) ...[
          _roundButton(Icons.tune_rounded, _showHostSettings, tooltip: 'Broadcast settings'),
          const SizedBox(width: 6),
          FilledButton(
            onPressed: widget.onEnd,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE0563B),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('End'),
          ),
        ] else
          _roundButton(Icons.close_rounded, widget.onClose, tooltip: 'Leave'),
      ],
    );
  }

  Widget _recipeChip() {
    return Material(
      color: Colors.black45,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: widget.onOpenRecipe,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.restaurant_menu_rounded, size: 15, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.recipeTitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _comments(BuildContext context) {
    final items = _feed.items;
    final height = MediaQuery.sizeOf(context).height * 0.30;
    return SizedBox(
      height: height,
      child: ShaderMask(
        // Comments fade out towards the top, as on any live app.
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.25],
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: Align(
          alignment: Alignment.bottomLeft,
          child: FractionallySizedBox(
            widthFactor: 0.78,
            child: ListView.builder(
              controller: _scroll,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: items.length,
              itemBuilder: (_, i) => _commentTile(items[i]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _commentTile(LiveFeedItem item) {
    final name = (item.userName ?? 'Someone').split(' ').first;
    late final InlineSpan content;
    if (item.isComment) {
      content = TextSpan(children: [
        TextSpan(text: '$name  ', style: const TextStyle(color: Color(0xFFFFD9A8), fontWeight: FontWeight.w700)),
        TextSpan(text: item.body ?? ''),
      ]);
    } else if (item.isGift) {
      content = TextSpan(children: [
        TextSpan(text: '$name ', style: const TextStyle(color: Color(0xFFFFD9A8), fontWeight: FontWeight.w700)),
        TextSpan(text: 'sent ${item.giftName} ${item.giftEmoji}${item.quantity > 1 ? ' ×${item.quantity}' : ''}'),
      ]);
    } else if (item.isJoin) {
      content = TextSpan(text: '$name joined', style: const TextStyle(color: Colors.white70));
    } else {
      content = TextSpan(
        text: item.body == 'ended' ? 'The broadcast has ended' : 'You are live',
        style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
      );
    }

    return GestureDetector(
      onLongPress: () => _showModeration(item),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(14)),
            child: Text.rich(content, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3)),
          ),
        ),
      ),
    );
  }

  Widget _composer(LiveRoomState state) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.only(left: 16, right: 4),
            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(24)),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    enabled: state.allowComments,
                    maxLength: 300,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      counterText: '',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      hintText: state.allowComments ? 'Say something kind…' : 'Comments are off',
                      hintStyle: const TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Send',
                  onPressed: state.allowComments && !_sending ? _send : null,
                  icon: const Icon(Icons.send_rounded, size: 20, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _roundButton(Icons.card_giftcard_rounded, _openGiftTray, tooltip: 'Send a gift', color: const Color(0xFFD9924A), size: 44),
        const SizedBox(width: 8),
        _roundButton(Icons.favorite_rounded, _like, tooltip: 'Like', color: const Color(0xFFE0563B), size: 44),
      ],
    );
  }

  Widget _endedCurtain() {
    final removed = _feed.removed;
    return ColoredBox(
      color: const Color(0xE60A1A20),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(removed ? Icons.block_rounded : Icons.check_circle_outline_rounded, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(
                removed ? 'You were removed from this broadcast' : 'This broadcast has ended',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              if (!removed) ...[
                const SizedBox(height: 8),
                Text(
                  '${_feed.likesCount} likes',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(onPressed: widget.onClose, child: const Text('Close')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill({required Widget child, Color color = Colors.black45}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: child,
    );
  }

  Widget _roundButton(IconData icon, VoidCallback? onTap, {String? tooltip, Color color = Colors.black45, double size = 36}) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: size, height: size, child: Icon(icon, color: Colors.white, size: size * 0.5)),
        ),
      ),
    );
  }
}

/// Bottom sheet listing the gift catalogue. Pick a gift, pick how many,
/// send — and stay open so a viewer can send several in a row.
class GiftTray extends StatefulWidget {
  const GiftTray({
    super.key,
    required this.gifts,
    required this.onSend,
    required this.hostName,
    this.currency,
    this.onTopUp,
  });

  final List<LiveGift> gifts;
  final Future<GiftSendResult> Function(LiveGift gift, int quantity) onSend;
  final String hostName;
  final String? currency;
  final VoidCallback? onTopUp;

  @override
  State<GiftTray> createState() => _GiftTrayState();
}

class _GiftTrayState extends State<GiftTray> {
  static const _quantities = [1, 5, 10];

  LiveGift? _selected;
  int _quantity = 1;
  bool _busy = false;
  String? _error;
  bool _needsTopUp = false;
  int? _balanceCents;

  Future<void> _send() async {
    final gift = _selected;
    if (gift == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _needsTopUp = false;
    });
    final result = await widget.onSend(gift, _quantity);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _balanceCents = result.balanceCents ?? _balanceCents;
      _error = result.ok ? null : result.message;
      _needsTopUp = result.needsTopUp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = _selected;
    return Container(
      decoration: const BoxDecoration(
        color: FriendColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: FriendColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text('Send ${widget.hostName.split(' ').first} a gift', style: theme.textTheme.titleMedium),
                  ),
                  if (_balanceCents != null)
                    Text(
                      'Wallet ${formatMoney(_balanceCents, widget.currency)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Gifts are paid from your wallet and support the host. They cannot be refunded.',
                style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.textSecondary),
              ),
              const SizedBox(height: 12),
              if (widget.gifts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No gifts available right now.')),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.gifts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (_, i) {
                    final gift = widget.gifts[i];
                    final isSelected = selected?.id == gift.id;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() {
                        _selected = gift;
                        _error = null;
                        _needsTopUp = false;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        decoration: BoxDecoration(
                          color: isSelected ? FriendColors.woodLight : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isSelected ? FriendColors.accent : Colors.transparent, width: 1.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(gift.emoji, style: const TextStyle(fontSize: 32)),
                            const SizedBox(height: 4),
                            Text(gift.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelMedium),
                            Text(
                              formatMoney(gift.priceCents, widget.currency),
                              style: theme.textTheme.labelSmall?.copyWith(color: FriendColors.accentDeep, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: FriendColors.error)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final q in _quantities) ...[
                    ChoiceChip(
                      label: Text('×$q'),
                      selected: _quantity == q,
                      onSelected: (_) => setState(() => _quantity = q),
                    ),
                    const SizedBox(width: 6),
                  ],
                  const Spacer(),
                  if (_needsTopUp && widget.onTopUp != null)
                    FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onTopUp!();
                      },
                      child: const Text('Top up wallet'),
                    )
                  else
                    FilledButton(
                      onPressed: selected == null || _busy ? null : _send,
                      style: FilledButton.styleFrom(backgroundColor: FriendColors.accentDeep),
                      child: Text(
                        selected == null
                            ? 'Choose a gift'
                            : _busy
                                ? 'Sending…'
                                : 'Send · ${formatMoney(selected.priceCents * _quantity, widget.currency)}',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
