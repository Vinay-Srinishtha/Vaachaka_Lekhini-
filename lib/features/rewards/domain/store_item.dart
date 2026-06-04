import 'package:equatable/equatable.dart';

enum StoreCategory {
  frames,
  books,
  tools,
  meditation;

  String get label => switch (this) {
        StoreCategory.frames => 'Frames',
        StoreCategory.books => 'Books',
        StoreCategory.tools => 'Tools',
        StoreCategory.meditation => 'Meditate',
      };
}

class StoreItem extends Equatable {
  const StoreItem({
    required this.id,
    required this.title,
    required this.category,
    required this.pricePoints,
    this.subtitle,
    this.glyph = '🛍',
    this.background = const [0xFFE0A85C, 0xFFA56A3D],
  });

  final String id;
  final String title;
  final String? subtitle;
  final StoreCategory category;
  final int pricePoints;
  final String glyph;
  final List<int> background;

  @override
  List<Object?> get props => [id];
}

const kStoreSeed = <StoreItem>[
  StoreItem(
    id: 'mala_beads',
    title: 'Digital Mala Beads',
    subtitle: 'Counter accessory',
    category: StoreCategory.tools,
    pricePoints: 500,
    glyph: '📿',
    background: [0xFF8C6C4A, 0xFF5A3C1A],
  ),
  StoreItem(
    id: 'exclusive_mantras',
    title: 'Exclusive Mantras',
    subtitle: 'Sacred chants',
    category: StoreCategory.tools,
    pricePoints: 1500,
    glyph: '🪨',
    background: [0xFFE8C28A, 0xFFA87C42],
  ),
  StoreItem(
    id: 'ebook_basics',
    title: 'Spiritual E-books',
    subtitle: 'Curated reading',
    category: StoreCategory.books,
    pricePoints: 800,
    glyph: '📖',
    background: [0xFF3A2818, 0xFF1A0E08],
  ),
  StoreItem(
    id: 'guided_meditations',
    title: 'Guided Meditations',
    subtitle: '7-day series',
    category: StoreCategory.meditation,
    pricePoints: 1000,
    glyph: '🧘',
    background: [0xFF7BAA88, 0xFF3D7558],
  ),
  StoreItem(
    id: 'photo_frame_rama',
    title: 'Rama Photo Frame',
    subtitle: 'Decorative',
    category: StoreCategory.frames,
    pricePoints: 300,
    glyph: '🖼',
    background: [0xFFFDC974, 0xFFD68A2A],
  ),
  StoreItem(
    id: 'mindfulness_cards',
    title: 'Mindfulness Cards',
    subtitle: 'Daily prompts',
    category: StoreCategory.meditation,
    pricePoints: 600,
    glyph: '🪷',
    background: [0xFFD9A6E5, 0xFF8A45A0],
  ),
];
