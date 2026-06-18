import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Increment this notifier after saving/removing a profile photo so every
/// open [KvlProfileAvatar] reloads immediately without needing a screen pop.
final avatarChangeNotifier = ValueNotifier<int>(0);

/// Shared profile avatar widget used across the app.
///
/// Shows the user's saved photo (stored locally via SharedPreferences under
/// `avatar_path_{profileId}`) when available, otherwise falls back to
/// a deterministic gradient circle with initials.
class KvlProfileAvatar extends StatefulWidget {
  const KvlProfileAvatar({
    super.key,
    required this.profileId,
    required this.initials,
    required this.size,
    this.textSize,
    this.gradientSeed,
    this.border,
    this.boxShadow,
  });

  final String profileId;
  final String initials;
  final double size;
  final double? textSize;

  /// Seed string for gradient color (defaults to profileId).
  final String? gradientSeed;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  static String prefsKey(String profileId) => 'avatar_path_$profileId';

  @override
  State<KvlProfileAvatar> createState() => _KvlProfileAvatarState();
}

class _KvlProfileAvatarState extends State<KvlProfileAvatar> {
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    avatarChangeNotifier.addListener(_onAvatarChanged);
    _load();
  }

  @override
  void didUpdateWidget(KvlProfileAvatar old) {
    super.didUpdateWidget(old);
    if (old.profileId != widget.profileId) _load();
  }

  @override
  void dispose() {
    avatarChangeNotifier.removeListener(_onAvatarChanged);
    super.dispose();
  }

  void _onAvatarChanged() => _load();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(KvlProfileAvatar.prefsKey(widget.profileId));
    if (path != null) {
      final file = File(path);
      final exists = await file.exists();
      if (exists) await FileImage(file).evict();
      if (mounted) setState(() => _imagePath = exists ? path : null);
    } else {
      if (mounted) setState(() => _imagePath = null);
    }
  }

  LinearGradient _gradient() {
    final seed = (widget.gradientSeed ?? widget.profileId).hashCode.abs();
    const palettes = [
      [Color(0xFF6C63FF), Color(0xFF3B28CC)], // violet
      [Color(0xFF0EA5E9), Color(0xFF0369A1)], // sky blue
      [Color(0xFF10B981), Color(0xFF065F46)], // emerald
      [Color(0xFFEC4899), Color(0xFF9D174D)], // rose
      [Color(0xFFF59E0B), Color(0xFFB45309)], // amber
      [Color(0xFF8B5CF6), Color(0xFF5B21B6)], // purple
      [Color(0xFF14B8A6), Color(0xFF0D7375)], // teal
    ];
    final colors = palettes[seed % palettes.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _imagePath != null;
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasPhoto ? null : _gradient(),
        border: widget.border,
        boxShadow: widget.boxShadow,
        image: hasPhoto
            ? DecorationImage(
                image: FileImage(File(_imagePath!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: hasPhoto
          ? null
          : Text(
              widget.initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: widget.textSize ?? widget.size * 0.38,
              ),
            ),
    );
  }
}
