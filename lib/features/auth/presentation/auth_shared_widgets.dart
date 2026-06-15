/// Shared widgets used across auth screens.
/// Keep this file small — only truly reused pieces belong here.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';

/// Translate an [AuthFailure] error code to the user's active language.
/// Falls back to [fallback] (the original English message) if the code is
/// unrecognised, so new server errors degrade gracefully.
String localizeAuthError(BuildContext context, {String? code, String? fallback}) {
  return switch (code) {
    'invalid_otp' => context.l10n.authErrorInvalidOtp,
    'invalid_mobile' => context.l10n.authErrorInvalidMobile,
    'account_not_found' => context.l10n.authErrorAccountNotFound,
    'account_exists' => context.l10n.authErrorAccountExists,
    'server_unavailable' => context.l10n.authErrorServerUnavailable,
    'no_internet' => context.l10n.authErrorNoInternet,
    'otp_expired' => context.l10n.authErrorOtpExpired,
    'server_error' => context.l10n.authErrorServerError,
    'too_many_attempts' => context.l10n.authErrorTooManyAttempts,
    'account_banned' => context.l10n.authErrorAccountBanned,
    _ => fallback ?? context.l10n.authErrorUnknown,
  };
}

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
  const AuthErrorBar(this.message, {super.key, this.onDismiss});
  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
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
        if (onDismiss != null)
          GestureDetector(
            onTap: onDismiss,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.close_rounded, size: 14, color: KvlColors.danger.withValues(alpha: 0.7)),
            ),
          ),
      ]),
    );
  }
}
