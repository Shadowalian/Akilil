import 'package:flutter/foundation.dart';

/// One entry of a live-stream feed: a comment, a gift, a like burst, someone
/// joining, or a system notice (started / ended / settings).
@immutable
class LiveFeedItem {
  const LiveFeedItem({
    required this.id,
    required this.type,
    this.body,
    this.payload = const {},
    this.userId,
    this.userName,
    this.avatarUrl,
  });

  final int id;
  final String type; // comment | gift | like | join | system
  final String? body;
  final Map<String, dynamic> payload;
  final int? userId;
  final String? userName;
  final String? avatarUrl;

  bool get isComment => type == 'comment';
  bool get isGift => type == 'gift';
  bool get isJoin => type == 'join';
  bool get isLike => type == 'like';
  bool get isSystem => type == 'system';

  /// Gift details when [isGift].
  Map<String, dynamic> get gift =>
      payload['gift'] is Map ? Map<String, dynamic>.from(payload['gift'] as Map) : const {};
  String get giftEmoji => (gift['emoji'] ?? '🎁').toString();
  String get giftName => (gift['name'] ?? 'Gift').toString();
  String get giftAnimation => (gift['animation'] ?? 'float').toString();
  int get quantity => (payload['quantity'] as num?)?.toInt() ?? 1;
  int get likeCount => (payload['count'] as num?)?.toInt() ?? 1;

  factory LiveFeedItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? Map<String, dynamic>.from(json['user'] as Map) : null;
    final payload = json['payload'];
    return LiveFeedItem(
      id: (json['id'] as num).toInt(),
      type: (json['type'] ?? 'comment').toString(),
      body: json['body'] as String?,
      payload: payload is Map ? Map<String, dynamic>.from(payload) : const {},
      userId: (user?['id'] as num?)?.toInt(),
      userName: user?['name'] as String?,
      avatarUrl: user?['avatar_url'] as String?,
    );
  }
}

/// An item of the gift catalogue (`GET /gifts`).
@immutable
class LiveGift {
  const LiveGift({
    required this.id,
    required this.slug,
    required this.name,
    required this.emoji,
    required this.priceCents,
    required this.animation,
  });

  final int id;
  final String slug;
  final String name;
  final String emoji;
  final int priceCents;
  final String animation; // float | burst | fullscreen

  factory LiveGift.fromJson(Map<String, dynamic> json) => LiveGift(
        id: (json['id'] as num).toInt(),
        slug: (json['slug'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        emoji: (json['emoji'] ?? '🎁').toString(),
        priceCents: (json['price_cents'] as num?)?.toInt() ?? 0,
        animation: (json['animation'] ?? 'float').toString(),
      );
}

/// Room state returned with every feed poll.
@immutable
class LiveRoomState {
  const LiveRoomState({
    this.status = 'live',
    this.viewerCount = 0,
    this.likesCount = 0,
    this.allowComments = true,
    this.allowGifts = true,
    this.giftsTotalCents,
  });

  final String status;
  final int viewerCount;
  final int likesCount;
  final bool allowComments;
  final bool allowGifts;

  /// Only the host receives this.
  final int? giftsTotalCents;

  bool get isLive => status == 'live';
  bool get isOver => status == 'ended' || status == 'cancelled';

  factory LiveRoomState.fromJson(Map<String, dynamic> json) => LiveRoomState(
        status: (json['status'] ?? 'live').toString(),
        viewerCount: (json['viewer_count'] as num?)?.toInt() ?? 0,
        likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
        allowComments: json['allow_comments'] != false,
        allowGifts: json['allow_gifts'] != false,
        giftsTotalCents: (json['gifts_total_cents'] as num?)?.toInt(),
      );
}

/// Outcome of trying to send a gift.
@immutable
class GiftSendResult {
  const GiftSendResult.sent({this.balanceCents, this.currency})
      : ok = true,
        needsTopUp = false,
        message = null,
        requiredCents = null;

  const GiftSendResult.failed(this.message, {this.needsTopUp = false, this.requiredCents, this.balanceCents, this.currency})
      : ok = false;

  final bool ok;

  /// The wallet could not cover it — offer a top-up.
  final bool needsTopUp;
  final String? message;
  final int? requiredCents;
  final int? balanceCents;
  final String? currency;
}
