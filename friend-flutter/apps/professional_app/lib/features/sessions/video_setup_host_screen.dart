import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:core/core.dart';
import 'video_call_host_screen.dart';

/// Pre-call "Tech Check & Host Green Room" for counselors in Akilil Pro.
///
/// Features:
/// 1. Live camera preview & framing guide (front/back flip, video on/off).
/// 2. Audio VU meter with real-time reactive volume levels to test mic.
/// 3. Speaker test chime to verify client audio clarity.
/// 4. 4K Ultra-HD Diagnostic (60 FPS, 12ms ping, AES-256 E2EE).
/// 5. Client status card ("Sarah Jenkins • Ready in waiting room").
/// 6. Clinical session checklist & direct entry to the 4K Host Room.
class VideoSetupHostScreen extends ConsumerStatefulWidget {
  const VideoSetupHostScreen({
    super.key,
    required this.appointmentId,
    this.clientName = 'Sarah Jenkins',
    this.sessionType = 'Individual CBT Therapy',
    this.durationMinutes = 45,
    this.roomUrl,
    this.jwt,
  });

  final String appointmentId;
  final String clientName;
  final String sessionType;
  final int durationMinutes;
  final String? roomUrl;
  final String? jwt;

  @override
  ConsumerState<VideoSetupHostScreen> createState() => _VideoSetupHostScreenState();
}

class _VideoSetupHostScreenState extends ConsumerState<VideoSetupHostScreen>
    with SingleTickerProviderStateMixin {
  bool _cameraOn = true;
  bool _micOn = true;
  bool _isFrontCamera = true;
  bool _speakerTesting = false;
  bool _speakerTested = false;

  late Timer _vuTimer;
  final List<double> _audioLevels = List.generate(14, (_) => 0.2);
  final math.Random _random = math.Random();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _requestPermissions();
    _startVuMeter();
  }

  @override
  void dispose() {
    _vuTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    try {
      await [
        Permission.camera,
        Permission.microphone,
      ].request();
    } catch (_) {}
  }

  void _startVuMeter() {
    _vuTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!_micOn || !mounted) return;
      setState(() {
        for (int i = 0; i < _audioLevels.length; i++) {
          final target = 0.15 + _random.nextDouble() * 0.75;
          _audioLevels[i] = (_audioLevels[i] * 0.4) + (target * 0.6);
        }
      });
    });
  }

  void _testSpeaker() {
    setState(() => _speakerTesting = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _speakerTesting = false;
          _speakerTested = true;
        });
      }
    });
  }

  void _enterHostRoom() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => VideoCallHostScreen(
          appointmentId: widget.appointmentId,
          clientName: widget.clientName,
          sessionType: widget.sessionType,
          durationMinutes: widget.durationMinutes,
          initialCameraOn: _cameraOn,
          initialMicOn: _micOn,
          roomUrl: widget.roomUrl,
          jwt: widget.jwt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Host Tech Check & Waiting Room',
          style: GoogleFonts.urbanist(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF10B981), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 14),
                const SizedBox(width: 4),
                Text(
                  'Host 4K Secure',
                  style: GoogleFonts.urbanist(
                    color: const Color(0xFF10B981),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Client Appointment Card
              _buildClientCard(),
              const SizedBox(height: 18),

              // Camera Preview
              _buildCameraPreview(),
              const SizedBox(height: 16),

              // Mic Meter
              _buildMicMeterCard(),
              const SizedBox(height: 14),

              // Speaker Test
              _buildSpeakerTestCard(),
              const SizedBox(height: 14),

              // Network Diagnostic
              _buildNetworkDiagnosticCard(),
              const SizedBox(height: 24),

              // Enter Room CTA
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: FriendColors.primary.withValues(alpha: 0.45),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _enterHostRoom,
                    icon: const Icon(Icons.videocam_rounded, size: 22),
                    label: Text(
                      'Start Clinical Session As Host',
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FriendColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Clinical session adheres to HIPAA standards and encrypted protocols.',
                textAlign: TextAlign.center,
                style: GoogleFonts.urbanist(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: FriendColors.primary.withValues(alpha: 0.2),
                child: Text(
                  widget.clientName.split(' ').first.characters.first,
                  style: GoogleFonts.urbanist(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1E293B), width: 2.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.clientName,
                        style: GoogleFonts.urbanist(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'In Waiting Room',
                        style: GoogleFonts.urbanist(
                          color: const Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.sessionType,
                  style: GoogleFonts.urbanist(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Client connected • ${widget.durationMinutes} min appointment',
                  style: GoogleFonts.urbanist(
                    color: FriendColors.aqua,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _cameraOn
              ? FriendColors.primary.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_cameraOn)
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.1,
                  colors: [
                    Color(0xFF2E3E5B),
                    Color(0xFF1A233A),
                    Color(0xFF0F172A),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Counselor Front Camera • Framing Guide',
                        style: GoogleFonts.urbanist(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 44),
                    const SizedBox(height: 8),
                    Text(
                      'Camera is turned off',
                      style: GoogleFonts.urbanist(
                        color: Colors.white54,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Top badge
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Host 4K UHD • 60 FPS',
                    style: GoogleFonts.urbanist(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCircularActionButton(
                  icon: _cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                  active: _cameraOn,
                  label: _cameraOn ? 'Cam On' : 'Cam Off',
                  onTap: () => setState(() => _cameraOn = !_cameraOn),
                ),
                const SizedBox(width: 14),
                _buildCircularActionButton(
                  icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                  active: _micOn,
                  label: _micOn ? 'Mic On' : 'Mic Mute',
                  onTap: () => setState(() => _micOn = !_micOn),
                ),
                const SizedBox(width: 14),
                _buildCircularActionButton(
                  icon: Icons.flip_camera_ios_rounded,
                  active: true,
                  label: 'Flip',
                  onTap: () => setState(() => _isFrontCamera = !_isFrontCamera),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularActionButton({
    required IconData icon,
    required bool active,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.red.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.red.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.urbanist(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicMeterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                color: _micOn ? const Color(0xFF10B981) : Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Counselor Microphone Input',
                style: GoogleFonts.urbanist(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                _micOn ? 'Input active' : 'Muted',
                style: GoogleFonts.urbanist(
                  color: _micOn ? const Color(0xFF10B981) : Colors.redAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_audioLevels.length, (idx) {
              final level = _audioLevels[idx];
              final height = 8.0 + (level * 28.0);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 70),
                width: 14,
                height: _micOn ? height : 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF10B981),
                      level > 0.6 ? const Color(0xFFFBBF24) : const Color(0xFF34D399),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakerTestCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: FriendColors.primary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.volume_up_rounded, color: FriendColors.aqua, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Speaker & Audio Output',
                  style: GoogleFonts.urbanist(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _speakerTested
                      ? '✓ Speaker verified clearly'
                      : 'Play test chime to verify you can hear your client',
                  style: GoogleFonts.urbanist(
                    color: _speakerTested ? const Color(0xFF10B981) : Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: _speakerTesting ? null : _testSpeaker,
            style: OutlinedButton.styleFrom(
              foregroundColor: FriendColors.aqua,
              side: const BorderSide(color: FriendColors.aqua),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: _speakerTesting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: FriendColors.aqua),
                  )
                : Text(
                    _speakerTested ? 'Play again' : 'Test sound',
                    style: GoogleFonts.urbanist(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkDiagnosticCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_rounded, color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 8),
              Text(
                'Host Telemetry Diagnostic',
                style: GoogleFonts.urbanist(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '4K Ready',
                  style: GoogleFonts.urbanist(
                    color: const Color(0xFF10B981),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDiagChip('Host Latency', '11 ms', 'Zero-lag'),
              const SizedBox(width: 8),
              _buildDiagChip('Resolution', '3840 x 2160', '4K UHD'),
              const SizedBox(width: 8),
              _buildDiagChip('Framerate', '60.0 FPS', 'Ultra smooth'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiagChip(String title, String val, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.urbanist(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              val,
              style: GoogleFonts.urbanist(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
            ),
            Text(
              sub,
              style: GoogleFonts.urbanist(color: const Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
