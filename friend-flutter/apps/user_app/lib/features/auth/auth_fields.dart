import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:core/core.dart';

import '../brand/figma_assets.dart';

/// Small brand lockup at the top of both auth screens.
class FreudAuthBrand extends StatelessWidget {
  const FreudAuthBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const FreudLogoBadge(size: 36),
        const SizedBox(width: 10),
        Text(
          'Akilil',
          style: GoogleFonts.urbanist(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: FriendColors.primary,
          ),
        ),
      ],
    );
  }
}

/// Labelled white pill field — the only input style in the auth flow.
/// Focus lifts a Serenity Green border plus a 4px green glow.
class FreudField extends StatefulWidget {
  const FreudField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final Widget? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<String>? autofillHints;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  @override
  State<FreudField> createState() => _FreudFieldState();
}

class _FreudFieldState extends State<FreudField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final radius = BorderRadius.circular(FriendRadii.pill);

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.urbanist(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.1,
            color: FriendColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: focused ? FriendElevation.focusRing : FriendElevation.card,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focus,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            autofillHints: widget.autofillHints,
            textInputAction: widget.textInputAction,
            validator: widget.validator,
            onFieldSubmitted: widget.onSubmitted,
            cursorColor: FriendColors.green,
            style: GoogleFonts.urbanist(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: FriendColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: FriendColors.textMuted,
              ),
              filled: true,
              fillColor: FriendColors.surface,
              prefixIcon: widget.icon == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(left: 20, right: 12),
                      child: widget.icon,
                    ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
              suffixIcon: widget.suffix,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 20,
              ),
              border: border(Colors.transparent, 0),
              enabledBorder: border(Colors.transparent, 0),
              focusedBorder: border(FriendColors.green, 1.6),
              errorBorder: border(FriendColors.error, 1.4),
              focusedErrorBorder: border(FriendColors.error, 1.6),
              errorStyle: GoogleFonts.urbanist(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: FriendColors.error,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Inline form error banner.
class FreudAuthError extends StatelessWidget {
  const FreudAuthError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: FriendColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(FriendRadii.medium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: FriendColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.urbanist(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: FriendColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Decorative social row — Akilil has no OAuth yet, so these are inert
/// placeholders that keep the Freud composition without faking a sign-in.
class FreudSocialRow extends StatelessWidget {
  const FreudSocialRow({super.key});

  static const _icons = [
    Icons.facebook_rounded,
    Icons.g_mobiledata_rounded,
    Icons.camera_alt_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final icon in _icons)
          Container(
            width: 52,
            height: 52,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              color: FriendColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: FriendColors.wood.withValues(alpha: 0.55),
            ),
          ),
      ],
    );
  }
}
