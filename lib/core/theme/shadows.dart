import 'package:flutter/widgets.dart';

abstract final class KvlShadows {
  static const card = [
    BoxShadow(
      color: Color(0x0F3A230C), // rgba(58,35,12,.06)
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];

  static const elevated = [
    BoxShadow(
      color: Color(0x143A230C), // rgba(58,35,12,.08)
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];

  static const lifted = [
    BoxShadow(
      color: Color(0x243A230C), // rgba(58,35,12,.14)
      blurRadius: 50,
      offset: Offset(0, 18),
    ),
  ];

  static const primaryGlow = [
    BoxShadow(
      color: Color(0x52E8893B), // rgba(232,137,59,.32)
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  static const tealGlow = [
    BoxShadow(
      color: Color(0x4D1F6F6B), // rgba(31,111,107,.3)
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];
}
