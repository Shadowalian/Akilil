/// Freud kit assets exported from Figma plus the chrome built around them.
library;

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class FigmaAssets {
  FigmaAssets._();

  static const _dir = 'assets/figma';

  /// Four-lobe Freud logomark. The SVG paints white, so every other ink
  /// colour has to come through a filter.
  static Widget logomark({double size = 32, Color color = Colors.white}) {
    return SvgPicture.asset(
      '$_dir/logomark.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  static Widget arrowRight({double size = 24, Color color = Colors.white}) {
    return SvgPicture.asset(
      '$_dir/arrow_right.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  static Widget email({double size = 22, Color color = FriendColors.wood}) {
    return SvgPicture.asset(
      '$_dir/email.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  static Widget lock({double size = 22, Color color = FriendColors.wood}) {
    return SvgPicture.asset(
      '$_dir/lock.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  static Widget mascot({double size = 260}) {
    return Image.asset(
      '$_dir/welcome_mascot.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

/// Brown disc carrying the white logomark — the Freud brand lockup.
class FreudLogoBadge extends StatelessWidget {
  const FreudLogoBadge({
    super.key,
    this.size = 64,
    this.background = FriendColors.primary,
    this.mark = Colors.white,
  });

  final double size;
  final Color background;
  final Color mark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Center(child: FigmaAssets.logomark(size: size * 0.5, color: mark)),
    );
  }
}

/// Serenity Green header that curves away under the auth title.
class FreudCurvedHeader extends StatelessWidget {
  const FreudCurvedHeader({
    super.key,
    this.height = 200,
    this.color = FriendColors.primary,
  });

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _BellyClipper(),
      child: Container(
        height: height,
        width: double.infinity,
        color: color,
        child: SafeArea(
          bottom: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: FigmaAssets.logomark(size: 54),
            ),
          ),
        ),
      ),
    );
  }
}

class _BellyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 48)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + 34,
        size.width,
        size.height - 48,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Aqua CTAs — 56 high, ExtraBold, soft lift + press feedback.
class FreudPillButton extends StatefulWidget {
  const FreudPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.background = FriendColors.primary,
    this.foreground = FriendColors.onPrimary,
    this.showArrow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final bool showArrow;

  @override
  State<FreudPillButton> createState() => _FreudPillButtonState();
}

class _FreudPillButtonState extends State<FreudPillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FriendRadii.pill);
    final enabled = widget.onPressed != null;

    return Listener(
      onPointerDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onPointerUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onPointerCancel: enabled ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: enabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _pressed
                        ? [
                            widget.background,
                            Color.lerp(widget.background, Colors.black, 0.12)!,
                          ]
                        : [
                            Color.lerp(widget.background, Colors.white, 0.12)!,
                            widget.background,
                          ],
                  )
                : null,
            color: enabled ? null : widget.background.withValues(alpha: 0.4),
            boxShadow: enabled && !_pressed ? FriendElevation.button : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: radius,
              splashColor: Colors.white.withValues(alpha: 0.16),
              child: SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.urbanist(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: widget.foreground,
                      ),
                    ),
                    if (widget.showArrow) ...[
                      const SizedBox(width: 10),
                      FigmaAssets.arrowRight(size: 20, color: widget.foreground),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Empathy Orange underlined link used under the auth forms.
class FreudLink extends StatelessWidget {
  const FreudLink({
    super.key,
    required this.leading,
    required this.label,
    required this.onTap,
  });

  final String leading;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          leading,
          style: GoogleFonts.urbanist(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: FriendColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            label,
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: FriendColors.accent,
              decoration: TextDecoration.underline,
              decorationColor: FriendColors.accent,
            ),
          ),
        ),
      ],
    );
  }
}
