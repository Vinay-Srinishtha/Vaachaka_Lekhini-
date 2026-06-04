import '../../features/mantras/domain/mantra.dart';
import '../theme/typography.dart';

class KvlLanguage {
  const KvlLanguage({
    required this.code,
    required this.label,
    required this.nativeLabel,
  });

  final String code;
  final String label;
  final String nativeLabel;

  static const english = KvlLanguage(
    code: 'en',
    label: 'English',
    nativeLabel: 'English',
  );
  static const telugu = KvlLanguage(
    code: 'te',
    label: 'Telugu',
    nativeLabel: 'తెలుగు',
  );
  static const hindi = KvlLanguage(
    code: 'hi',
    label: 'Hindi',
    nativeLabel: 'हिन्दी',
  );
  static const kannada = KvlLanguage(
    code: 'kn',
    label: 'Kannada',
    nativeLabel: 'ಕನ್ನಡ',
  );

  static const fallback = english;
  static const all = [english, telugu, hindi, kannada];

  static KvlLanguage byCode(String? code) {
    for (final lang in all) {
      if (lang.code == code) return lang;
    }
    return fallback;
  }

  static List<KvlLanguage> availableFor(List<Mantra> mantras) {
    final hasTelugu = mantras.any((m) => (m.name.telugu ?? '').isNotEmpty);
    final hasKannada = mantras.any((m) => (m.name.kannada ?? '').isNotEmpty);
    return [english, if (hasTelugu) telugu, hindi, if (hasKannada) kannada];
  }
}

extension MantraNameLanguageX on MantraName {
  String displayForLanguage(String code) => switch (code) {
    'te' => telugu ?? devanagari,
    'kn' => kannada ?? devanagari,
    'hi' => devanagari,
    _ => roman,
  };

  MantraScript scriptForLanguage(String code) => switch (code) {
    'te' when (telugu ?? '').isNotEmpty => MantraScript.telugu,
    'kn' when (kannada ?? '').isNotEmpty => MantraScript.kannada,
    'hi' => MantraScript.devanagari,
    _ => MantraScript.latin,
  };
}

extension KvlLanguageTextX on String {
  MantraScript get mantraScriptForLanguage => switch (this) {
    'te' => MantraScript.telugu,
    'kn' => MantraScript.kannada,
    'hi' => MantraScript.devanagari,
    _ => MantraScript.latin,
  };
}
