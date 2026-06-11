import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Labeled text field with the KVL look (cream surface, soft border).
class KvlInput extends StatelessWidget {
  const KvlInput({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLength,
    this.autofocus = false,
    this.focusNode,
    this.inputFormatters,
    this.textInputAction,
    this.onSubmitted,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final int? maxLength;
  final bool autofocus;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          Text(label!, style: KvlText.caption(11.5).copyWith(color: KvlColors.inkSoft, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          onChanged: onChanged,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: KvlText.ui(13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: KvlText.ui(13).copyWith(color: KvlColors.muted),
            prefixIcon: prefix,
            suffixIcon: suffix,
            isDense: true,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: KvlSpacing.md, vertical: KvlSpacing.md),
            border: OutlineInputBorder(
              borderRadius: KvlRadius.brMD,
              borderSide: const BorderSide(color: KvlColors.border, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: KvlRadius.brMD,
              borderSide: const BorderSide(color: KvlColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: KvlRadius.brMD,
              borderSide: const BorderSide(color: KvlColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: readOnly ? KvlColors.surfaceWarm : KvlColors.surface,
          ),
        ),
      ],
    );
  }
}
