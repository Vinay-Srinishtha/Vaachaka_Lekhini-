/// Shared widgets used across auth screens.
/// Keep this file small — only truly reused pieces belong here.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme.dart';

// ─────────────────────────────────────────────────────────────
// AuthMobileFormatter
// Formats raw digit input as "XXXXX XXXXX" (max 10 digits).
// ─────────────────────────────────────────────────────────────

class AuthMobileFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(_, TextEditingValue n) {
    final d = n.text.replaceAll(RegExp(r'\D'), '');
    final s = d.length > 10 ? d.substring(0, 10) : d;
    final f = s.length > 5 ? '${s.substring(0, 5)} ${s.substring(5)}' : s;
    return TextEditingValue(
        text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}

// ─────────────────────────────────────────────────────────────
// AuthErrorBar
// Compact inline error bar (red, no action button).
// ─────────────────────────────────────────────────────────────

class AuthErrorBar extends StatelessWidget {
  const AuthErrorBar(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: KvlColors.danger.withValues(alpha: 0.07),
        borderRadius: KvlRadius.brSM,
        border: Border.all(color: KvlColors.danger.withValues(alpha: 0.28)),
      ),
      child: Row(children: [
        Icon(Icons.error_outline_rounded, size: 15, color: KvlColors.danger),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: KvlText.caption(11.5).copyWith(color: KvlColors.danger)),
        ),
      ]),
    );
  }
}
