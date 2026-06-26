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
    'invalid_otp'         => context.l10n.authErrorInvalidOtp,
    'invalid_mobile'      => context.l10n.authErrorInvalidMobile,
    'account_not_found'   => context.l10n.authErrorAccountNotFound,
    'account_exists'      => context.l10n.authErrorAccountExists,
    'server_unavailable'  => context.l10n.authErrorServerUnavailable,
    'no_internet'         => context.l10n.authErrorNoInternet,
    'otp_expired'         => context.l10n.authErrorOtpExpired,
    'server_error'        => context.l10n.authErrorServerError,
    'too_many_attempts'   => context.l10n.authErrorTooManyAttempts,
    'account_banned'      => context.l10n.authErrorAccountBanned,
    'account_suspended'   => context.l10n.authErrorAccountSuspended,
    'otp_max_attempts'    => context.l10n.authErrorOtpMaxAttempts,
    'otp_already_used'    => context.l10n.authErrorOtpAlreadyUsed,
    'cooldown_active'     => context.l10n.authErrorCooldownActive,
    'daily_limit_reached' => context.l10n.authErrorDailyLimitReached,
    'delivery_failure'    => context.l10n.authErrorDeliveryFailure,
    _ => fallback ?? context.l10n.authErrorUnknown,
  };
}

/// Returns true if this error code is account-level (shown as a card, not a
/// generic error bar). The caller should suppress the bar for these codes.
bool isAccountLevelError(String? code) => const {
  'account_exists',
  'account_not_found',
  'account_banned',
  'account_suspended',
  'otp_max_attempts',
}.contains(code);

// ─────────────────────────────────────────────────────────────
// AuthMobileFormatter
// Formats raw digit input as "XXXXX XXXXX" (max 10 digits).
// ─────────────────────────────────────────────────────────────

class AuthMobileFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(_, TextEditingValue n) {
    var d = n.text.replaceAll(RegExp(r'\D'), '');
    // Cap at 12 digits (10-digit or full 12-digit with country code)
    if (d.length > 12) d = d.substring(0, 12);
    // Format: space after 5th digit for 10-digit, or after 2nd+7th for 12-digit
    String f;
    if (d.length <= 5) {
      f = d;
    } else if (d.length <= 10) {
      f = '${d.substring(0, 5)} ${d.substring(5)}';
    } else {
      // 11 or 12 digits — show as-is spaced
      f = d;
    }
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

// ─────────────────────────────────────────────────────────────
// AuthBannedCard
// Shown when account is banned/suspended (403). Replaces the
// normal flow; user cannot proceed.
// ─────────────────────────────────────────────────────────────

class AuthBannedCard extends StatelessWidget {
  const AuthBannedCard({super.key, required this.suspended});
  final bool suspended; // true = admin-suspended, false = policy-banned

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: KvlColors.danger.withValues(alpha: 0.06),
        borderRadius: KvlRadius.brMD,
        border: Border.all(color: KvlColors.danger.withValues(alpha: 0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.gpp_bad_rounded, size: 18, color: KvlColors.danger),
          const SizedBox(width: 8),
          Text(
            suspended ? 'Account Deactivated' : 'Account Suspended',
            style: KvlText.ui(13).copyWith(
              fontWeight: FontWeight.w700,
              color: KvlColors.danger,
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Text(
          suspended
              ? context.l10n.authErrorAccountSuspended
              : context.l10n.authErrorAccountBanned,
          style: KvlText.caption(11.5).copyWith(color: KvlColors.danger.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 12),
        Text(
          'Contact support: support@srinishtha.com',
          style: KvlText.caption(11).copyWith(
            color: KvlColors.danger.withValues(alpha: 0.7),
            decoration: TextDecoration.underline,
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AuthOtpLockedCard
// Shown when max OTP attempts are exceeded (code is locked).
// ─────────────────────────────────────────────────────────────

class AuthOtpLockedCard extends StatelessWidget {
  const AuthOtpLockedCard({super.key, required this.onRequestNew});
  final VoidCallback onRequestNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: KvlRadius.brMD,
        border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.lock_outline_rounded, size: 17, color: Color(0xFFE65100)),
          const SizedBox(width: 8),
          Text(
            'Code Locked',
            style: KvlText.ui(13).copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE65100),
            ),
          ),
        ]),
        const SizedBox(height: 5),
        Text(
          context.l10n.authErrorOtpMaxAttempts,
          style: KvlText.caption(11.5).copyWith(color: KvlColors.inkSoft),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onRequestNew,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE65100),
              borderRadius: KvlRadius.brPill,
            ),
            alignment: Alignment.center,
            child: Text(
              'Request New Code',
              style: KvlText.ui(13, FontWeight.w700).copyWith(color: Colors.white),
            ),
          ),
        ),
      ]),
    );
  }
}
