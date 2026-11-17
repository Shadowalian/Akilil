import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';

/// Two-segment English / Amharic switch shared by both apps.
class FriendLanguageSwitch extends StatelessWidget {
  const FriendLanguageSwitch({super.key, required this.amharic, required this.onChanged});

  final bool amharic;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: FriendColors.recessed,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(label: 'EN', semantics: 'English', selected: !amharic, onTap: () => onChanged(false)),
          _Segment(label: 'አማ', semantics: 'አማርኛ', selected: amharic, onTap: () => onChanged(true)),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.semantics, required this.selected, required this.onTap});

  final String label;
  final String semantics;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semantics,
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!selected) HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 32),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? FriendColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? const [BoxShadow(color: Color(0x1417191C), blurRadius: 3, offset: Offset(0, 1))]
                : null,
          ),
          child: Text(
            label,
            style: friendFont(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? FriendColors.textPrimary : FriendColors.textMuted,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
