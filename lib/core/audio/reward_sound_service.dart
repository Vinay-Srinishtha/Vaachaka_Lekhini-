import 'package:audioplayers/audioplayers.dart';

/// Plays the temple-bell chime when reward points are earned.
/// Uses a single shared AudioPlayer — concurrent calls simply restart it.
class RewardSoundService {
  RewardSoundService._();

  static final RewardSoundService instance = RewardSoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _contextConfigured = false;

  /// The bell must NOT grab exclusive audio focus, otherwise playing it
  /// interrupts the live mic stream (`record` plugin) and the voice
  /// recogniser stops captioning the moment a reward point is earned.
  ///
  /// Android: request no focus + a sonification usage so playback coexists
  /// with the ongoing recording. iOS: play in a category that mixes with
  /// (and ducks under) other audio instead of deactivating the mic session.
  static final AudioContext _coexistContext = AudioContext(
    android: AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playAndRecord,
      options: {
        AVAudioSessionOptions.mixWithOthers,
        AVAudioSessionOptions.duckOthers,
      },
    ),
  );

  Future<void> playBell() async {
    if (!_contextConfigured) {
      await _player.setAudioContext(_coexistContext);
      _contextConfigured = true;
    }
    await _player.stop();
    await _player.play(AssetSource('audio/temple_bell.mp3'));
  }
}
