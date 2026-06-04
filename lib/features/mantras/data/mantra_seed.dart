import '../../../core/widgets/mantra_thumb.dart';
import '../domain/mantra.dart';

/// Canonical seed list of mantras. Add new mantras here and they'll appear
/// in every selection surface. v1 is read-only — user-supplied mantras
/// are scheduled for v1.1.
const List<Mantra> kMantraSeed = [
  Mantra(
    id: 'sri_rama',
    name: MantraName(
      devanagari: 'श्री राम',
      roman: 'Sri Rama',
      telugu: 'శ్రీ రామ',
      kannada: 'ಶ್ರೀ ರಾಮ',
    ),
    description:
        'The Sri Rama mantra is a sacred chant that invokes the divine energy of Lord Rama, an incarnation of Vishnu. It is revered for its power to bestow peace, righteousness, and spiritual liberation. Chanting this mantra helps purify the mind, body, and soul, and is a cornerstone of the Koti Vachika Lekhini practice, guiding devotees on their spiritual journey.',
    thumbPalette: MantraThumbPalette.saffron,
    tags: {MantraTag.peace, MantraTag.righteousness, MantraTag.liberation},
    deity: 'Rama',
  ),
  Mantra(
    id: 'om_namah_shivaya',
    name: MantraName(
      devanagari: 'ॐ नमः शिवाय',
      roman: 'Om Namah Shivaya',
      telugu: 'ఓం నమః శివాయ',
      kannada: 'ಓಂ ನಮಃ ಶಿವಾಯ',
    ),
    description:
        'A popular five-syllable mantra dedicated to Lord Shiva. Chanting it is believed to cleanse the heart of impurities and bring inner stillness.',
    thumbPalette: MantraThumbPalette.shiva,
    tags: {MantraTag.peace, MantraTag.liberation, MantraTag.devotion},
    deity: 'Shiva',
  ),
  Mantra(
    id: 'gayatri',
    name: MantraName(
      devanagari: 'ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं',
      roman: 'Gayatri Mantra',
      telugu: 'గాయత్రీ మంత్రం',
      kannada: 'ಗಾಯತ್ರೀ ಮಂತ್ರ',
    ),
    description:
        'One of the most sacred mantras in the Vedas — a prayer for the awakening of intellect and wisdom through the radiance of the divine Savitr.',
    thumbPalette: MantraThumbPalette.gayatri,
    tags: {MantraTag.wisdom, MantraTag.enlightenment},
  ),
  Mantra(
    id: 'maha_mrityunjaya',
    name: MantraName(
      devanagari: 'ॐ त्र्यम्बकं यजामहे',
      roman: 'Maha Mrityunjaya',
      telugu: 'మహా మృత్యుంజయ',
      kannada: 'ಮಹಾ ಮೃತ್ಯುಂಜಯ',
    ),
    description:
        'A powerful mantra of healing and protection, dedicated to Lord Shiva. Traditionally recited to overcome fear, illness, and adversity.',
    thumbPalette: MantraThumbPalette.maha,
    tags: {MantraTag.healing, MantraTag.protection, MantraTag.strength},
    deity: 'Shiva',
  ),
  Mantra(
    id: 'hanuman_chalisa',
    name: MantraName(
      devanagari: 'हनुमान चालीसा',
      roman: 'Hanuman Chalisa',
      telugu: 'హనుమాన్ చాలీసా',
      kannada: 'ಹನುಮಾನ್ ಚಾಲೀಸಾ',
    ),
    description:
        'A devotional hymn of forty verses extolling Hanuman, invoked for strength, courage, and steadfast devotion.',
    thumbPalette: MantraThumbPalette.hanuman,
    tags: {MantraTag.strength, MantraTag.courage, MantraTag.devotion, MantraTag.protection},
    deity: 'Hanuman',
  ),
  Mantra(
    id: 'shankara',
    name: MantraName(
      devanagari: 'शंकर',
      roman: 'Shankara',
      telugu: 'శంకర',
      kannada: 'ಶಂಕರ',
    ),
    description: 'A simple invocation of Lord Shiva as Shankara — the auspicious one.',
    thumbPalette: MantraThumbPalette.shiva,
    tags: {MantraTag.peace, MantraTag.devotion},
    deity: 'Shiva',
  ),
  Mantra(
    id: 'jai_sri_krishna',
    name: MantraName(
      devanagari: 'जय श्री कृष्ण',
      roman: 'Jai Sri Krishna',
      telugu: 'జై శ్రీ కృష్ణ',
      kannada: 'ಜೈ ಶ್ರೀ ಕೃಷ್ಣ',
    ),
    description: 'A joyful greeting to Lord Krishna — a mantra of devotion and deliverance.',
    thumbPalette: MantraThumbPalette.krishna,
    tags: {MantraTag.devotion, MantraTag.liberation},
    deity: 'Krishna',
  ),
  Mantra(
    id: 'narayana',
    name: MantraName(
      devanagari: 'नारायण',
      roman: 'Narayana',
      telugu: 'నారాయణ',
      kannada: 'ನಾರಾಯಣ',
    ),
    description: 'A short, single-word mantra honouring Lord Vishnu (Narayana), the sustainer.',
    thumbPalette: MantraThumbPalette.vishnu,
    tags: {MantraTag.peace, MantraTag.devotion, MantraTag.protection},
    deity: 'Vishnu',
  ),
  Mantra(
    id: 'om_namo_bhagavate_vasudevaya',
    name: MantraName(
      devanagari: 'ॐ नमो भगवते वासुदेवाय',
      roman: 'Om Namo Bhagavate Vasudevaya',
      telugu: 'ఓం నమో భగవతే వాసుదేవాయ',
      kannada: 'ಓಂ ನಮೋ ಭಗವತೇ ವಾಸುದೇವಾಯ',
    ),
    description:
        'Chanting this mantra is believed to attract wealth, prosperity, and resolve financial difficulties by invoking the grace of Lord Vishnu.',
    thumbPalette: MantraThumbPalette.vishnu,
    tags: {MantraTag.wealth, MantraTag.prosperity, MantraTag.devotion},
    deity: 'Vishnu',
    recommendedCount: 108,
    recommendedDays: 40,
  ),
];
