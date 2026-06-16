import 'package:flutter_test/flutter_test.dart';
import 'package:vachika_lekhini/features/enrolment/voice/data/voice_enrolment_service.dart';

void main() {
  group('VoicePhraseMatcher.countOccurrences', () {
    // ── Basic counting ──────────────────────────────────────────────────────

    test('counts every complete repeated mantra exactly once', () {
      expect(
        VoicePhraseMatcher.countOccurrences('नारायण, नारायण! नारायण', 'नारायण'),
        3,
      );
    });

    test('single occurrence mid-string', () {
      expect(VoicePhraseMatcher.countOccurrences('ॐ नारायण ॐ', 'नारायण'), 1);
    });

    test('ignores a different recognized word', () {
      expect(VoicePhraseMatcher.countOccurrences('राम', 'नारायण'), 0);
    });

    test('returns 0 on empty haystack', () {
      expect(VoicePhraseMatcher.countOccurrences('', 'नारायण'), 0);
    });

    test('returns 0 on empty needle', () {
      expect(VoicePhraseMatcher.countOccurrences('नारायण', ''), 0);
    });

    // ── Word-boundary enforcement ───────────────────────────────────────────

    test('does not count a partial-word substring (needle inside longer word)', () {
      // "नारा" is a prefix of "नारायण" but should NOT count as "नारायण"
      expect(VoicePhraseMatcher.countOccurrences('नारा', 'नारायण'), 0);
    });

    test('does not count when phrase is embedded inside a compound word', () {
      // "राम" should not match inside "सीताराम"
      expect(VoicePhraseMatcher.countOccurrences('सीताराम', 'राम'), 0);
    });

    test('counts correctly when same phrase appears as standalone and embedded', () {
      // "राम" standalone (space-separated) counts once; "सीताराम" does NOT add another
      expect(
        VoicePhraseMatcher.countOccurrences('राम सीताराम राम', 'राम'),
        2,
      );
    });

    // ── Boundary characters ─────────────────────────────────────────────────

    test('matches at start of string', () {
      expect(VoicePhraseMatcher.countOccurrences('नारायण नारायण', 'नारायण'), 2);
    });

    test('matches at end of string', () {
      expect(
        VoicePhraseMatcher.countOccurrences('जय नारायण', 'नारायण'),
        1,
      );
    });

    test('counts when separated by commas', () {
      expect(
        VoicePhraseMatcher.countOccurrences('नारायण,नारायण,नारायण', 'नारायण'),
        3,
      );
    });

    test('counts when separated by exclamation marks', () {
      expect(
        VoicePhraseMatcher.countOccurrences('नारायण!नारायण', 'नारायण'),
        2,
      );
    });

    // ── Multi-word phrases ──────────────────────────────────────────────────

    test('counts multi-word mantra', () {
      expect(
        VoicePhraseMatcher.countOccurrences(
          'ॐ नमः शिवाय ॐ नमः शिवाय',
          'ॐ नमः शिवाय',
        ),
        2,
      );
    });

    test('does not double-count overlapping multi-word phrase', () {
      // Non-overlapping match: advances past the first occurrence before searching
      expect(
        VoicePhraseMatcher.countOccurrences(
          'नारायण नारायण नारायण',
          'नारायण नारायण',
        ),
        1,
      );
    });

    // ── Normalisation ───────────────────────────────────────────────────────

    test('handles leading/trailing whitespace in inputs', () {
      expect(
        VoicePhraseMatcher.countOccurrences('  नारायण  ', ' नारायण '),
        1,
      );
    });

    // ── High-frequency chanting (multiple per window) ───────────────────────

    test('counts 5 rapid repetitions in one window', () {
      const chant = 'नारायण नारायण नारायण नारायण नारायण';
      expect(VoicePhraseMatcher.countOccurrences(chant, 'नारायण'), 5);
    });

    test('counts two chants with surrounding ASR noise words', () {
      expect(
        VoicePhraseMatcher.countOccurrences(
          'the नारायण something नारायण end',
          'नारायण',
        ),
        2,
      );
    });
  });
}
