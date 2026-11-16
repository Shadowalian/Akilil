import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

/// Host session room — starts the appointment and opens the live Meet room.
class SessionHostScreen extends ConsumerStatefulWidget {
  const SessionHostScreen({super.key, required this.appointmentId});
  final String appointmentId;

  @override
  ConsumerState<SessionHostScreen> createState() => _SessionHostScreenState();
}

class _SessionHostScreenState extends ConsumerState<SessionHostScreen> {
  String? _roomUrl;
  String? _jwt;
  String? _displayName;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post<Map<String, dynamic>>(
        '/appointments/${widget.appointmentId}/session/start',
      );
      final data = res.data ?? const {};
      final session = (data['session'] as Map<String, dynamic>?) ?? data;
      if (!mounted) return;
      setState(() {
        _roomUrl = (session['room_url'] as String?)?.trim();
        _jwt = session['token'] as String?;
        if (data['display_name'] is String &&
            (data['display_name'] as String).isNotEmpty) {
          _displayName = data['display_name'] as String;
        }
        if (_roomUrl == null || _roomUrl!.isEmpty) {
          _roomUrl = 'https://meet.ffmuc.net/akilil-${widget.appointmentId}';
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _roomUrl = 'https://meet.ffmuc.net/akilil-${widget.appointmentId}';
        _loading = false;
      });
    }
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/sessions');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: FriendDarkColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2.5,
                color: FriendColors.primary,
              ),
              SizedBox(height: 16),
              Text(
                'Starting live session…',
                style: TextStyle(
                  color: FriendDarkColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _roomUrl == null) {
      return Scaffold(
        backgroundColor: FriendDarkColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error ?? "Couldn't start the session.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: FriendDarkColors.textSecondary),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _start();
                }, child: const Text('Retry')),
                TextButton(onPressed: _leave, child: const Text('Back')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: FriendDarkColors.background,
      body: SafeArea(
        child: JitsiSessionView(
          roomUrl: _roomUrl!,
          jwt: _jwt,
          displayName: _displayName,
          onLeave: _leave,
        ),
      ),
    );
  }
}
