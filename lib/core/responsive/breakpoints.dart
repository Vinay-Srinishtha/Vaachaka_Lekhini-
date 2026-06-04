import 'package:flutter/widgets.dart';

abstract final class KvlBreakpoints {
  static const double phone = 600;
  static const double tablet = 1024;
}

enum KvlDeviceClass { phone, tablet, desktop }

extension KvlMediaQueryX on BuildContext {
  KvlDeviceClass get deviceClass {
    final w = MediaQuery.sizeOf(this).width;
    if (w < KvlBreakpoints.phone) return KvlDeviceClass.phone;
    if (w < KvlBreakpoints.tablet) return KvlDeviceClass.tablet;
    return KvlDeviceClass.desktop;
  }

  bool get isPhone => deviceClass == KvlDeviceClass.phone;
  bool get isTablet => deviceClass == KvlDeviceClass.tablet;
  bool get isDesktop => deviceClass == KvlDeviceClass.desktop;
  bool get isWide => deviceClass != KvlDeviceClass.phone;
}

/// Renders a different widget per device class. Phone is mandatory;
/// tablet falls back to phone, desktop to tablet, then phone.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.phone, this.tablet, this.desktop});

  final WidgetBuilder phone;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    final cls = context.deviceClass;
    return switch (cls) {
      KvlDeviceClass.phone => phone(context),
      KvlDeviceClass.tablet => (tablet ?? phone)(context),
      KvlDeviceClass.desktop => (desktop ?? tablet ?? phone)(context),
    };
  }
}

/// Constrains a phone-shaped layout to a max width on tablet/desktop so screens
/// designed at 390px don't stretch awkwardly. Use for single-column pages.
class CenteredPhoneCanvas extends StatelessWidget {
  const CenteredPhoneCanvas({super.key, required this.child, this.maxWidth = 520});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
