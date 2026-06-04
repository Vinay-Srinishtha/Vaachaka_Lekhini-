/// Pure earn/spend rates. Centralised so we can tune the economy in
/// one place. Phase 9 keeps these client-side; the server validates.
abstract final class RewardRules {
  /// Earn for hitting a program's daily target.
  static const int dailyTarget = 50;

  /// Earn for crossing a lifetime-count milestone (10L, 50L, 1Cr…).
  /// 500 for any milestone for now; tweak if needed.
  static const int milestoneCross = 500;

  /// Earn when a referred friend signs up. (Phase 9 wires the trigger.)
  static const int friendReferral = 100;

  /// Optional small spend for donating points to charity.
  static const int charityDonation = 50;

  /// Milestone thresholds in lifetime chants (Indian-system labelling).
  static const milestoneThresholds = <int>[
    100000,   // 1 Lakh
    500000,
    1000000,  // 10 Lakh
    2500000,
    5000000,  // 50 Lakh
    10000000, // 1 Crore
  ];

  /// Returns the milestone label crossed when totals move from [before] to [after],
  /// or null if no boundary was crossed.
  static String? milestoneCrossedLabel(int before, int after) {
    for (final t in milestoneThresholds) {
      if (before < t && after >= t) {
        return _label(t);
      }
    }
    return null;
  }

  static String _label(int n) {
    if (n >= 10000000) return '${n ~/ 10000000} Cr Chants';
    if (n >= 100000) return '${n ~/ 100000} Lakh Chants';
    return '$n Chants';
  }
}
