import 'package:flutter/material.dart';

import 'package:core/core.dart';

import '../../l10n/language_toggle.dart';
import '../brand/brand_assets.dart';

/// Layout shared by sign in, sign up and the other account screens:
/// wordmark and language switch on top, a left-aligned title, then the
/// form, capped at a comfortable reading width.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.onBack,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback? onBack;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: FriendColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(FriendLayout.horizontal, 12, FriendLayout.horizontal, 0),
              child: Row(
                children: [
                  if (onBack != null) ...[FriendBackButton(onPressed: onBack), const SizedBox(width: 12)],
                  BrandAssets.logo(),
                  const Spacer(),
                  const LanguageToggle(compact: true),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(header: true, child: Text(title, style: theme.textTheme.headlineLarge)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(color: FriendColors.textSecondary),
                          ),
                        ],
                        const SizedBox(height: 32),
                        ...children,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (footer != null)
              Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 16), child: footer!),
          ],
        ),
      ),
    );
  }
}

/// Field with its label above it. Uses the theme's input style.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
    this.suffix,
    this.helper,
    this.trailingLabel,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<String>? autofillHints;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final String? helper;

  /// A small action shown on the label's line, such as "Forgot password?".
  final Widget? trailingLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthLabel(label, trailing: trailingLabel),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(hintText: hint, suffixIcon: suffix, helperText: helper, helperMaxLines: 3),
        ),
      ],
    );
  }
}

class AuthLabel extends StatelessWidget {
  const AuthLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: FriendColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A read-only field that opens a picker, styled exactly like [AuthField].
class AuthPickerField extends StatelessWidget {
  const AuthPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.icon = Icons.calendar_today_outlined,
    this.helper,
  });

  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final IconData icon;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthLabel(label),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FriendRadii.medium),
          child: InputDecorator(
            decoration: InputDecoration(suffixIcon: Icon(icon, size: 20), helperText: helper, helperMaxLines: 3),
            child: Text(
              value ?? placeholder,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: value == null ? FriendColors.textMuted : FriendColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Inline error under a form.
class AuthError extends StatelessWidget {
  const AuthError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: FriendColors.errorContainer,
          borderRadius: BorderRadius.circular(FriendRadii.medium),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.error_outline_rounded, size: 18, color: FriendColors.error),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: FriendColors.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Don't have an account? Sign up" line.
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({super.key, required this.leading, required this.label, required this.onTap});

  final String leading;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(leading.trim(), style: theme.textTheme.bodyMedium?.copyWith(color: FriendColors.textSecondary)),
        TextButton(onPressed: onTap, child: Text(label)),
      ],
    );
  }
}
