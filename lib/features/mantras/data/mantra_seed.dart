import '../../../core/widgets/mantra_thumb.dart';
import '../domain/mantra.dart';

/// Canonical seed list of mantras shown in the app.
const List<Mantra> kMantraSeed = [
  Mantra(
    id: 'narayana',
    name: MantraName(
      devanagari: 'नारायण',
      roman: 'Narayana',
      telugu: 'నారాయణ',
      kannada: 'ನಾರಾಯಣ',
    ),
    description:
        'A short, single-word mantra honouring Lord Vishnu (Narayana), the sustainer of the universe. Chanting this mantra invokes divine protection, peace, and devotion.',
    thumbPalette: MantraThumbPalette.vishnu,
    tags: {MantraTag.peace, MantraTag.devotion, MantraTag.protection},
    deity: 'Vishnu',
  ),
  Mantra(
    id: 'shankara',
    name: MantraName(
      devanagari: 'शंकर',
      roman: 'Shankara',
      telugu: 'శంకర',
      kannada: 'ಶಂಕರ',
    ),
    description:
        'A simple invocation of Lord Shiva as Shankara — the auspicious one who bestows peace, bliss, and liberation upon all devotees.',
    thumbPalette: MantraThumbPalette.shiva,
    tags: {MantraTag.peace, MantraTag.devotion},
    deity: 'Shiva',
  ),
  Mantra(
    id: 'sri_krishna',
    name: MantraName(
      devanagari: 'श्री कृष्ण',
      roman: 'Sri Krishna',
      telugu: 'శ్రీ కృష్ణ',
      kannada: 'ಶ್ರೀ ಕೃಷ್ಣ',
    ),
    description:
        'An invocation of Lord Krishna, the divine teacher of the Bhagavad Gita. Chanting Sri Krishna fills the heart with joy, devotion, and spiritual wisdom.',
    thumbPalette: MantraThumbPalette.krishna,
    tags: {MantraTag.devotion, MantraTag.liberation, MantraTag.wisdom},
    deity: 'Krishna',
  ),
  Mantra(
    id: 'sri_rama',
    name: MantraName(
      devanagari: 'श्री राम',
      roman: 'Sri Rama',
      telugu: 'శ్రీ రామ',
      kannada: 'ಶ್ರೀ ರಾಮ',
    ),
    description:
        'The Sri Rama mantra invokes the divine energy of Lord Rama, an incarnation of Vishnu, revered for bestowing peace, righteousness, and spiritual liberation.',
    thumbPalette: MantraThumbPalette.saffron,
    tags: {MantraTag.peace, MantraTag.righteousness, MantraTag.liberation},
    deity: 'Rama',
  ),
  Mantra(
    id: 'shiva',
    name: MantraName(
      devanagari: 'शिव',
      roman: 'Shiva',
      telugu: 'శివ',
      kannada: 'ಶಿವ',
    ),
    description:
        'A direct invocation of Lord Shiva — the destroyer of ego and transformer of the soul. This single-word mantra is powerful in its simplicity and depth.',
    thumbPalette: MantraThumbPalette.shiva,
    tags: {MantraTag.peace, MantraTag.liberation, MantraTag.devotion},
    deity: 'Shiva',
  ),
  Mantra(
    id: 'sri_matre_namaha',
    name: MantraName(
      devanagari: 'श्री मात्रे नमः',
      roman: 'Sri Matre Namaha',
      telugu: 'శ్రీ మాత్రే నమః',
      kannada: 'ಶ್ರೀ ಮಾತ್ರೆ ನಮಃ',
    ),
    description:
        'A salutation to the Divine Mother — honouring the supreme feminine energy that nurtures, protects, and guides all of creation.',
    thumbPalette: MantraThumbPalette.matre,
    tags: {MantraTag.devotion, MantraTag.protection, MantraTag.peace},
    deity: 'Devi',
  ),
];
