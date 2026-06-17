import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// 6-box OTP entry with auto-advance, backspace-retreat, paste support,
/// and a "Paste" button that reads digits from the clipboard.
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
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _value => _controllers.map((c) => c.text).join();

  void _fillDigits(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final take = digits.length.clamp(0, widget.length);
    for (var i = 0; i < widget.length; i++) {
      _controllers[i].text = i < take ? digits[i] : '';
    }
    // Move focus to last filled box (or first empty)
    final focusIdx = (take - 1).clamp(0, widget.length - 1);
    _focusNodes[focusIdx].requestFocus();
    final current = _value;
    widget.onChanged?.call(current);
    if (current.length == widget.length) {
      widget.onCompleted?.call(current);
    }
  }

  void _handleChange(int index, String value) {
    if (value.length > 1) {
      // Paste / autofill from system keyboard
      _fillDigits(value);
      return;
    }
    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    final current = _value;
    widget.onChanged?.call(current);
    if (current.length == widget.length) {
      widget.onCompleted?.call(current);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;
    _fillDigits(data!.text!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
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
                  maxLength: widget.length, // allow full paste into first box
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: KvlColors.ink,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: KvlColors.surface,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: KvlRadius.brSM,
                      borderSide:
                          const BorderSide(color: KvlColors.border, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: KvlRadius.brSM,
                      borderSide: const BorderSide(
                          color: KvlColors.primary, width: 1.5),
                    ),
                  ),
                  onChanged: (v) => _handleChange(i, v),
                ),
              ),
              if (i < widget.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pasteFromClipboard,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              border: Border.all(
                  color: KvlColors.primary.withValues(alpha: 0.4), width: 1.2),
              borderRadius: KvlRadius.brPill,
              color: KvlColors.primary.withValues(alpha: 0.06),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.content_paste_rounded,
                    size: 13, color: KvlColors.primaryDeep),
                const SizedBox(width: 5),
                Text(
                  'Paste OTP',
                  style: KvlText.caption(11.5).copyWith(
                    color: KvlColors.primaryDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
