import 'package:flutter/widgets.dart';

/// Spacing scale (4-pt grid).
abstract final class KvlSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  // Standard insets
  static const EdgeInsets pageInset = EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const EdgeInsets cardInset = EdgeInsets.all(lg);
  static const EdgeInsets tightCardInset = EdgeInsets.all(md);

  // Common gaps as SizedBox for convenience in Column/Row children
  static const SizedBox gapXS = SizedBox(width: xs, height: xs);
  static const SizedBox gapSM = SizedBox(width: sm, height: sm);
  static const SizedBox gapMD = SizedBox(width: md, height: md);
  static const SizedBox gapLG = SizedBox(width: lg, height: lg);
  static const SizedBox gapXL = SizedBox(width: xl, height: xl);
}

/// Border radius scale.
abstract final class KvlRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;

  static const BorderRadius brSM = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMD = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLG = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXL = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brPill = BorderRadius.all(Radius.circular(pill));
}
