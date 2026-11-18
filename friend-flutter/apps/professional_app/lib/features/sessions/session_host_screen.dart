import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:friend_professional/l10n/tr.dart';
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
        _loading = false;
        if (_roomUrl == null || _roomUrl!.isEmpty) {
          _error = "Couldn't open the session room.";
        }
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = apiErrorMessage(e.response?.data, "Couldn't open the session room.");
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Couldn't open the session room.";
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
      return Scaffold(
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
                tr('Starting live session…'),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: FriendDarkColors.textSecondary),
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
                }, child: Text(tr('Retry'))),
                TextButton(onPressed: _leave, child: Text(tr('Back'))),
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
