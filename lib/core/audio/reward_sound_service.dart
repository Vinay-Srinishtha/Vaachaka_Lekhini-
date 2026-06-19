import 'package:audioplayers/audioplayers.dart';

/// Plays the temple-bell chime when reward points are earned.
/// Uses a single shared AudioPlayer — concurrent calls simply restart it.
class RewardSoundService {
  RewardSoundService._();

  static final RewardSoundService instance = RewardSoundService._();

  final AudioPlayer _player = AudioPlayer();

  Future<void> playBell() async {
    await _player.stop();
    await _player.play(AssetSource('audio/temple_bell.mp3'));
  }
}
