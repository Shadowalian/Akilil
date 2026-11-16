import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:core/core.dart';

import '../../router.dart';

/// Client session room — Stitch pre-flight chrome, then Jitsi Meet WebView.
class SessionRoomScreen extends ConsumerStatefulWidget {
  const SessionRoomScreen({super.key, required this.appointmentId});
  final String appointmentId;

  @override
  ConsumerState<SessionRoomScreen> createState() => _SessionRoomScreenState();
}

class _SessionRoomScreenState extends ConsumerState<SessionRoomScreen> {
  bool _loading = true;
  bool _admitted = false;
  String? _roomUrl;
  String? _jwt;
  String? _displayName;
  String? _clinicianName;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    final dio = ref.read(dioProvider);
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/appointments/${widget.appointmentId}/session/start',
      );
      final data = res.data ?? const {};
      final session = (data['session'] as Map<String, dynamic>?) ?? data;
      if (!mounted) return;
      setState(() {
        _roomUrl = (session['room_url'] as String?)?.trim();
        _jwt = session['token'] as String?;
        _clinicianName = (data['professional_name'] as String?) ??
            (data['display_name'] as String?);
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
      context.go('/appointments');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SessionConnectingView(
        message: 'Preparing your sanctuary chamber…',
      );
    }

    if (!_admitted) {
      return Scaffold(
        backgroundColor: FriendColors.background,
        appBar: FriendStitchGlassHeader(
          title: 'Pre Session Waiting Room',
          onBack: _leave,
          onSos: () => context.push(AppRoutes.crisis),
          showProfileAvatar: false,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            FriendLayout.horizontal,
            12,
            FriendLayout.horizontal,
            24,
          ),
          children: [
            _WaitingRoomCard(clinicianName: _clinicianName ?? 'Your clinician'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FriendColors.surfaceLowest,
                borderRadius: BorderRadius.circular(FriendRadii.medium),
                boxShadow: FriendElevation.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.videocam_outlined, color: FriendColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Camera & audio check',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: FriendTypeScale.headlineSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When you enter the chamber, video runs inside Akilil Meet with end-to-end encryption. You can stay voice-only if you prefer.',
                    style: GoogleFonts.inter(
                      fontSize: FriendTypeScale.bodySmall,
                      height: 1.45,
                      color: FriendColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const FriendVaultBadge(label: 'Jitsi Secure Mesh • E2EE Addis-01'),
          ],
        ),
        bottomNavigationBar: FriendStitchStickyBar(
          primaryLabel: 'Enter Sanctuary Chamber',
          primaryEnabled: _roomUrl != null,
          onPrimary: () => setState(() => _admitted = true),
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
          onSos: () => context.push(AppRoutes.crisis),
        ),
      ),
    );
  }
}

class _WaitingRoomCard extends StatelessWidget {
  const _WaitingRoomCard({required this.clinicianName});
  final String clinicianName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FriendColors.surfaceLowest,
        borderRadius: BorderRadius.circular(FriendRadii.medium),
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
                  color: FriendColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(FriendRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FriendLivePulse(size: 8),
                    const SizedBox(width: 6),
                    Text(
                      'CHAMBER RESERVED',
                      style: GoogleFonts.inter(
                        fontSize: FriendTypeScale.micro,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: FriendColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(Icons.lock_outline_rounded, size: 16, color: FriendColors.primary),
              const SizedBox(width: 4),
              Text(
                'E2EE',
                style: GoogleFonts.inter(
                  fontSize: FriendTypeScale.micro,
                  fontWeight: FontWeight.w700,
                  color: FriendColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  color: FriendColors.accent,
                  backgroundColor: FriendColors.surfaceContainerHigh,
                  value: 0.72,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinicianName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: FriendTypeScale.headlineSmall,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reviewing your clinical intake and will admit you momentarily.',
                      style: GoogleFonts.inter(
                        fontSize: FriendTypeScale.bodySmall,
                        color: FriendColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
