import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../responsive/breakpoints.dart';
import 'kvl_top_bar.dart';

/// Standard page chrome — KvlTopBar + a body wrapped in a phone-shaped canvas
/// on wider screens so phone-designed layouts don't sprawl on tablet.
class KvlScaffold extends StatelessWidget {
  const KvlScaffold({
    super.key,
    required this.body,
    this.title,
    this.subtitle,
    this.showBack = true,
    this.leading,
    this.trailing,
    this.onBack,
    this.bottomNavigationBar,
    this.padding = const EdgeInsets.fromLTRB(
      KvlSpacing.lg,
      0,
      KvlSpacing.lg,
      KvlSpacing.lg,
    ),
    this.scrollable = false,
  });

  final Widget body;
  final String? title;
  final String? subtitle;
  final bool showBack;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onBack;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final padded = Padding(
      padding: scrollable
          ? EdgeInsetsDirectional.only(bottom: viewInsets.bottom).add(padding)
          : padding,
      child: body,
    );
    final bodyWidget = scrollable
        ? SingleChildScrollView(child: padded)
        : padded;

    final framed = CenteredPhoneCanvas(child: bodyWidget);

    return PopScope(
      // When a custom onBack is provided, we intercept and call it.
      // Otherwise allow the framework to pop naturally (works for pushed routes).
      canPop: onBack == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Only reached when canPop == false, i.e. onBack is set.
        onBack!();
      },
      child: Scaffold(
        backgroundColor: KvlColors.bg,
        appBar:
            (title == null && leading == null && trailing == null && !showBack)
            ? null
            : KvlTopBar(
                title: title,
                subtitle: subtitle,
                leading: leading,
                trailing: trailing,
                onBack: onBack,
                showBack: showBack,
              ),
        body: framed,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
