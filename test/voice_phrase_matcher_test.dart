import 'package:flutter_test/flutter_test.dart';
import 'package:vachika_lekhini/features/enrolment/voice/data/voice_enrolment_service.dart';

void main() {
  group('VoicePhraseMatcher', () {
    test('counts every complete repeated mantra exactly once', () {
      expect(
        VoicePhraseMatcher.countOccurrences('नारायण, नारायण! नारायण', 'नारायण'),
        3,
      );
    });

    test('ignores a different recognized word', () {
      expect(VoicePhraseMatcher.countOccurrences('राम', 'नारायण'), 0);
    });

    test('does not count a partial word', () {
      expect(VoicePhraseMatcher.countOccurrences('नारा', 'नारायण'), 0);
    });
  });
}
