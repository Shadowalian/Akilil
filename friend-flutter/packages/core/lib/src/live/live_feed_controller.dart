import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../util/money.dart';
import 'live_models.dart';

/// Drives one live room: keeps the comment list and room state fresh,
/// surfaces gifts / likes as streams for the effects layer, and sends the
/// viewer's own comments, likes and gifts.
///
/// Transport is a cursor poll of `GET /live-streams/{id}/events`. That call
/// is also the viewer's heartbeat, so it must keep running while watching.
class LiveFeedController extends ChangeNotifier {
  LiveFeedController({
    required Dio dio,
    required this.streamId,
    this.pollInterval = const Duration(seconds: 2),
  }) : _dio = dio;

  final Dio _dio;
  final int streamId;
  final Duration pollInterval;

  static const _maxVisible = 150;

  final List<LiveFeedItem> _items = [];
  final Set<int> _seen = {};
  final _gifts = StreamController<LiveFeedItem>.broadcast();
  final _likes = StreamController<int>.broadcast();

  Timer? _pollTimer;
  Timer? _likeTimer;
  int _cursor = 0;
  int _pendingLikes = 0;
  bool _busy = false;
  bool _primed = false;
  bool _disposed = false;

  LiveRoomState _state = const LiveRoomState();
  bool _removed = false;
  int _localLikes = 0;

  /// Comments, joins and notices, oldest first.
  List<LiveFeedItem> get items => List.unmodifiable(_items);
  LiveRoomState get state => _state;

  /// The host removed this viewer.
  bool get removed => _removed;
  bool get isOver => _state.isOver;

  /// Likes including taps not yet confirmed by the server.
  int get likesCount => _state.likesCount + _localLikes;

  /// Gifts as they arrive — feed these to [GiftEffectsLayer].
  Stream<LiveFeedItem> get gifts => _gifts.stream;

  /// Like bursts from other people (count per burst).
  Stream<int> get likes => _likes.stream;

  void start() {
    _poll();
    _pollTimer ??= Timer.periodic(pollInterval, (_) => _poll());
  }

  Future<void> _poll() async {
    if (_busy || _disposed || _removed) return;
    _busy = true;
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/live-streams/$streamId/events',
        queryParameters: {if (_cursor > 0) 'after': _cursor},
      );
      final data = res.data ?? const {};
      final events = ((data['events'] as List?) ?? const [])
          .map((e) => LiveFeedItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      for (final item in events) {
        // History loaded on the first poll must not replay gift effects.
        _ingest(item, animate: _primed);
      }
      final removedIds = ((data['removed_ids'] as List?) ?? const []).map((e) => (e as num).toInt()).toSet();
      if (removedIds.isNotEmpty) {
        _items.removeWhere((i) => removedIds.contains(i.id));
      }

      _cursor = (data['cursor'] as num?)?.toInt() ?? _cursor;
      if (data['state'] is Map) {
        _state = LiveRoomState.fromJson(Map<String, dynamic>.from(data['state'] as Map));
        _localLikes = _pendingLikes;
      }
      _primed = true;
      if (_state.isOver) _pollTimer?.cancel();
      _notify();
    } on DioException catch (e) {
      final body = e.response?.data;
      if (e.response?.statusCode == 403 && body is Map && body['code'] == 'removed') {
        _removed = true;
        _pollTimer?.cancel();
        _notify();
      }
      // Anything else: a dropped poll. The next tick retries.
    } finally {
      _busy = false;
    }
  }

  void _ingest(LiveFeedItem item, {required bool animate}) {
    if (!_seen.add(item.id)) return;

    if (item.isGift) {
      if (animate) _gifts.add(item);
      _items.add(item);
    } else if (item.isLike) {
      if (animate) _likes.add(item.likeCount);
    } else if (item.isSystem) {
      // Only the notices worth a line in the chat.
      if (item.body == 'started' || item.body == 'ended') _items.add(item);
    } else {
      _items.add(item);
    }
    if (_items.length > _maxVisible) {
      _items.removeRange(0, _items.length - _maxVisible);
    }
  }

  /// Returns an error message, or null when the comment was posted.
  Future<String?> sendComment(String body) async {
    final text = body.trim();
    if (text.isEmpty) return null;
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/live-streams/$streamId/comments',
        data: {'body': text},
      );
      final event = res.data?['event'];
      if (event is Map) {
        _ingest(LiveFeedItem.fromJson(Map<String, dynamic>.from(event)), animate: false);
        _notify();
      }
      return null;
    } on DioException catch (e) {
      return apiErrorMessage(e.response?.data, "Couldn't send your comment");
    }
  }

  /// Register a tap. Taps are batched and flushed about once a second.
  void tapLike() {
    _pendingLikes++;
    _localLikes++;
    _notify();
    _likeTimer ??= Timer(const Duration(milliseconds: 900), _flushLikes);
  }

  Future<void> _flushLikes() async {
    _likeTimer = null;
    final count = _pendingLikes;
    if (count == 0 || _disposed) return;
    _pendingLikes = 0;
    try {
      await _dio.post('/live-streams/$streamId/likes', data: {'count': count > 50 ? 50 : count});
    } on DioException {
      // Likes are decorative; losing a batch is fine.
    }
  }

  Future<GiftSendResult> sendGift(LiveGift gift, {int quantity = 1}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/live-streams/$streamId/gifts',
        data: {'gift_id': gift.id, 'quantity': quantity},
      );
      final data = res.data ?? const {};
      final event = data['event'];
      if (event is Map) {
        // The sender sees their own gift immediately.
        _ingest(LiveFeedItem.fromJson(Map<String, dynamic>.from(event)), animate: true);
        _notify();
      }
      return GiftSendResult.sent(
        balanceCents: (data['balance_cents'] as num?)?.toInt(),
        currency: data['currency'] as String?,
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      final map = body is Map ? body : const {};
      return GiftSendResult.failed(
        apiErrorMessage(body, "Couldn't send the gift"),
        needsTopUp: e.response?.statusCode == 402,
        requiredCents: (map['required_cents'] as num?)?.toInt(),
        balanceCents: (map['balance_cents'] as num?)?.toInt(),
        currency: map['currency'] as String?,
      );
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    _likeTimer?.cancel();
    _gifts.close();
    _likes.close();
    super.dispose();
  }
}
