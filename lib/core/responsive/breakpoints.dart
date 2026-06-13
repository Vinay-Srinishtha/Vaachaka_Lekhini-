import 'package:flutter/widgets.dart';

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
