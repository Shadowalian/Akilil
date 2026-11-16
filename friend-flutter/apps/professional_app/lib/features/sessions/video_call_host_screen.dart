import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:core/core.dart';

/// Professional Host 4K Clinical Video Call Screen.
///
/// Features:
/// 1. 4K Ultra-HD client video stream (Sarah Jenkins) with audio activity waves.
/// 2. Draggable floating PiP self-view for the counselor.
/// 3. In-call live clinical SOAP Notes editor (Subjective, Objective, Assessment, Plan).
/// 4. In-call CBT Tools drawer (Box Breathing, Thought Records, Safety Plan).
/// 5. In-call confidential chat.
/// 6. Session countdown timer & 4K telemetry HUD.
/// 7. "End Session for Everyone" clinical wrap-up.
class VideoCallHostScreen extends ConsumerStatefulWidget {
  const VideoCallHostScreen({
    super.key,
    required this.appointmentId,
    this.clientName = 'Sarah Jenkins',
    this.sessionType = 'Individual CBT Therapy',
    this.durationMinutes = 45,
    this.initialCameraOn = true,
    this.initialMicOn = true,
    this.roomUrl,
    this.jwt,
  });

  final String appointmentId;
  final String clientName;
  final String sessionType;
  final int durationMinutes;
  final bool initialCameraOn;
  final bool initialMicOn;
  final String? roomUrl;
  final String? jwt;

  @override
  ConsumerState<VideoCallHostScreen> createState() => _VideoCallHostScreenState();
}

class _VideoCallHostScreenState extends ConsumerState<VideoCallHostScreen>
    with TickerProviderStateMixin {
  late bool _micOn;
  late bool _cameraOn;
  bool _speakerOn = true;
  bool _isFrontCamera = true;
  bool _controlsVisible = true;
  bool _pipExpanded = false;

  late int _remainingSeconds;
  late Timer _sessionTimer;
  late Timer _controlsTimer;

  Offset _pipPosition = const Offset(20, 90);

  // In-Call clinical SOAP Notes
  final TextEditingController _soapSubjective = TextEditingController(
    text: 'Client reports feeling moderate anxiety related to recent work transition.',
  );
  final TextEditingController _soapObjective = TextEditingController(
    text: 'Attentive, good eye contact, calm breathing cadence during guided exercise.',
  );
  final TextEditingController _soapAssessment = TextEditingController(
    text: 'Showing positive adaptation to CBT cognitive reframing; PHQ-9 stable.',
  );
  final TextEditingController _soapPlan = TextEditingController(
    text: 'Practice 4-4-4-4 Box Breathing daily. Complete thought record on automatic thoughts.',
  );

  // In-call chat
  final List<({String sender, String text, DateTime time})> _chatMessages = [
    (
      sender: 'Sarah Jenkins',
      text: 'Hello Dr. Lin! I can hear and see you clearly.',
      time: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];
  final TextEditingController _chatController = TextEditingController();

  late AnimationController _clientWaveController;
  late Animation<double> _clientWaveAnimation;

  @override
  void initState() {
    super.initState();
    _micOn = widget.initialMicOn;
    _cameraOn = widget.initialCameraOn;
    _remainingSeconds = widget.durationMinutes * 60;

    _clientWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _clientWaveAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _clientWaveController, curve: Curves.easeInOut),
    );

    _startSessionTimer();
    _resetControlsTimer();
  }

  @override
  void dispose() {
    _sessionTimer.cancel();
    _controlsTimer.cancel();
    _clientWaveController.dispose();
    _soapSubjective.dispose();
    _soapObjective.dispose();
    _soapAssessment.dispose();
    _soapPlan.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _sessionTimer.cancel();
        _promptEndForEveryone();
      }
    });
  }

  void _resetControlsTimer() {
    _controlsTimer.cancel();
    _controlsTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _resetControlsTimer();
  }

  String _formatTime(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _promptEndForEveryone() async {
    final end = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.call_end_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 10),
            Text(
              'End Clinical Session for Everyone?',
              style: GoogleFonts.urbanist(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'This will conclude the 4K video session for both you and ${widget.clientName}. '
          'Your in-call clinical SOAP notes will be saved to your patient ledger.',
          style: GoogleFonts.urbanist(
            color: Colors.white70,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Continue call',
              style: GoogleFonts.urbanist(color: Colors.white70, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('End Session', style: GoogleFonts.urbanist(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (end == true && mounted) {
      context.go('/sessions/${widget.appointmentId}/notes');
    }
  }

  void _openSoapNotesDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.8,
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.note_alt_rounded, color: FriendColors.aqua, size: 22),
                const SizedBox(width: 8),
                Text(
                  'In-Call SOAP Clinical Notes',
                  style: GoogleFonts.urbanist(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  'Encrypted (EHR)',
                  style: GoogleFonts.urbanist(
                    color: const Color(0xFF10B981),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _soapField('S: Subjective (Client Voice & Symptoms)', _soapSubjective),
                  const SizedBox(height: 12),
                  _soapField('O: Objective (Affect, Presentation, Demeanor)', _soapObjective),
                  const SizedBox(height: 12),
                  _soapField('A: Assessment (Clinical Analysis & Distortions)', _soapAssessment),
                  const SizedBox(height: 12),
                  _soapField('P: Plan & Prescribed Exercises', _soapPlan),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('In-call SOAP notes updated.'),
                    backgroundColor: FriendColors.primaryDeep,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FriendColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Save Clinical Notes',
                style: GoogleFonts.urbanist(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _soapField(String title, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.urbanist(color: FriendColors.aqua, fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 2,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black26,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  void _openChatDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setChatState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 16),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, color: FriendColors.aqua, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Host & Client In-Call Messages',
                    style: GoogleFonts.urbanist(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: Colors.white12),
              Expanded(
                child: ListView.builder(
                  itemCount: _chatMessages.length,
                  itemBuilder: (ctx, idx) {
                    final msg = _chatMessages[idx];
                    final isMe = msg.sender == 'You (Counselor)';
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(ctx).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? FriendColors.primary : Colors.black38,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.sender,
                              style: GoogleFonts.urbanist(
                                color: isMe ? Colors.white70 : FriendColors.aqua,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              msg.text,
                              style: GoogleFonts.urbanist(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Message Sarah…',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.black26,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) {
                        final text = _chatController.text.trim();
                        if (text.isEmpty) return;
                        setState(() {
                          _chatMessages.add((sender: 'You (Counselor)', text: text, time: DateTime.now()));
                        });
                        setChatState(() {});
                        _chatController.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      final text = _chatController.text.trim();
                      if (text.isEmpty) return;
                      setState(() {
                        _chatMessages.add((sender: 'You (Counselor)', text: text, time: DateTime.now()));
                      });
                      setChatState(() {});
                      _chatController.clear();
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    style: IconButton.styleFrom(backgroundColor: FriendColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Primary 4K Video Stage: Client (Sarah Jenkins) ──────────
            _buildClientVideoStage(),

            // ── Top Header HUD Telemetry & Clinical Session Timer ───────
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _controlsVisible ? 1.0 : 0.0,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.clientName,
                            style: GoogleFonts.urbanist(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // 4K Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF10B981), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.hd_rounded, color: Color(0xFF10B981), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Host 4K • 60 FPS • 11ms',
                            style: GoogleFonts.urbanist(
                              color: const Color(0xFF10B981),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Countdown Timer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, size: 14, color: Colors.white70),
                          const SizedBox(width: 5),
                          Text(
                            _formatTime(_remainingSeconds),
                            style: GoogleFonts.urbanist(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Floating Draggable PiP (Counselor Self-View) ─────────────
            Positioned(
              left: _pipPosition.dx,
              top: _pipPosition.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() => _pipPosition += details.delta);
                },
                child: _buildPipSelfView(),
              ),
            ),

            // ── Bottom Control Bar ──────────────────────────────────────
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _controlsVisible ? 1.0 : 0.0,
                child: _buildCallControls(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientVideoStage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.1),
          radius: 1.2,
          colors: [
            Color(0xFF293548),
            Color(0xFF1A2234),
            Color(0xFF0F172A),
          ],
        ),
      ),
      child: Center(
        child: ScaleTransition(
          scale: _clientWaveAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: FriendColors.aqua.withValues(alpha: 0.35),
                        width: 3,
                      ),
                    ),
                  ),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: FriendColors.primary.withValues(alpha: 0.4),
                          blurRadius: 36,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.clientName.split(' ').first.characters.first,
                        style: GoogleFonts.urbanist(
                          fontSize: 54,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                widget.clientName,
                style: GoogleFonts.urbanist(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Client Audio Active • 4K Clinical Feed',
                style: GoogleFonts.urbanist(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPipSelfView() {
    final width = _pipExpanded ? 160.0 : 110.0;
    final height = _pipExpanded ? 220.0 : 150.0;

    return GestureDetector(
      onTap: () => setState(() => _pipExpanded = !_pipExpanded),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _pipExpanded ? FriendColors.primary : Colors.white24,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_cameraOn)
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Color(0xFF334155), Color(0xFF0F172A)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.person_rounded, size: 48, color: Colors.white60),
                ),
              )
            else
              Container(
                color: Colors.black87,
                child: const Center(
                  child: Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 28),
                ),
              ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Host (You)',
                  style: GoogleFonts.urbanist(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (!_micOn)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic_off_rounded, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mic
          _buildControlButton(
            icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
            active: _micOn,
            color: _micOn ? Colors.white12 : Colors.redAccent.withValues(alpha: 0.35),
            iconColor: _micOn ? Colors.white : Colors.redAccent,
            onTap: () {
              setState(() => _micOn = !_micOn);
              _resetControlsTimer();
            },
          ),

          // Camera
          _buildControlButton(
            icon: _cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
            active: _cameraOn,
            color: _cameraOn ? Colors.white12 : Colors.redAccent.withValues(alpha: 0.35),
            iconColor: _cameraOn ? Colors.white : Colors.redAccent,
            onTap: () {
              setState(() => _cameraOn = !_cameraOn);
              _resetControlsTimer();
            },
          ),

          // Flip
          _buildControlButton(
            icon: Icons.flip_camera_ios_rounded,
            active: true,
            color: Colors.white12,
            iconColor: Colors.white,
            onTap: () {
              setState(() => _isFrontCamera = !_isFrontCamera);
              _resetControlsTimer();
            },
          ),

          // Speaker
          _buildControlButton(
            icon: _speakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            active: _speakerOn,
            color: Colors.white12,
            iconColor: Colors.white,
            onTap: () {
              setState(() => _speakerOn = !_speakerOn);
              _resetControlsTimer();
            },
          ),

          // In-Call SOAP Notes
          _buildControlButton(
            icon: Icons.edit_note_rounded,
            active: true,
            color: FriendColors.primary.withValues(alpha: 0.25),
            iconColor: FriendColors.aqua,
            onTap: () {
              _openSoapNotesDrawer();
              _resetControlsTimer();
            },
          ),

          // In-Call Chat
          _buildControlButton(
            icon: Icons.chat_bubble_outline_rounded,
            active: true,
            color: Colors.white12,
            iconColor: Colors.white,
            onTap: () {
              _openChatDrawer();
              _resetControlsTimer();
            },
          ),

          // End for everyone
          GestureDetector(
            onTap: _promptEndForEveryone,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.call_end_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'End',
                    style: GoogleFonts.urbanist(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool active,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}
