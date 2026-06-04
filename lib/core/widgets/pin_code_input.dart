import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';

/// 6-box OTP entry with auto-advance, backspace-retreat, and paste support.
/// Calls [onCompleted] when all 6 digits are entered.
class PinCodeInput extends StatefulWidget {
  const PinCodeInput({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.autofocus = true,
  });

  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool autofocus;

  @override
  State<PinCodeInput> createState() => _PinCodeInputState();
}

class _PinCodeInputState extends State<PinCodeInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _value => _controllers.map((c) => c.text).join();

  void _handleChange(int index, String value) {
    if (value.length > 1) {
      // Paste / autofill: distribute characters across boxes.
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < widget.length; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final filled = digits.length.clamp(0, widget.length - 1);
      _focusNodes[filled].requestFocus();
    } else if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    widget.onChanged?.call(_value);
    if (_value.length == widget.length) {
      widget.onCompleted?.call(_value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < widget.length; i++) ...[
          SizedBox(
            width: 40,
            height: 48,
            child: TextField(
              controller: _controllers[i],
              focusNode: _focusNodes[i],
              autofocus: widget.autofocus && i == 0,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: KvlColors.ink),
              decoration: InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: KvlColors.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: KvlRadius.brSM,
                  borderSide: const BorderSide(color: KvlColors.border, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: KvlRadius.brSM,
                  borderSide: const BorderSide(color: KvlColors.primary, width: 1.5),
                ),
              ),
              onChanged: (v) => _handleChange(i, v),
            ),
          ),
          if (i < widget.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}
