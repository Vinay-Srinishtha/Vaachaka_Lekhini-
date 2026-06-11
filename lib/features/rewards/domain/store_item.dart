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
    required this.pricePoints,
    this.subtitle,
    this.imageUrl,
    this.category,
    this.glyph = '🛍',
    this.background = const [0xFFE0A85C, 0xFFA56A3D],
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final StoreCategory? category;
  final int pricePoints;
  final String glyph;
  final List<int> background;

  factory StoreItem.fromJson(Map<String, dynamic> j) {
    StoreCategory? cat;
    final catRaw = j['category'] as String?;
    if (catRaw != null) {
      cat = StoreCategory.values.where((c) => c.name == catRaw).firstOrNull;
    }

    List<int> bg = const [0xFFE0A85C, 0xFFA56A3D];
    final bgRaw = j['background'];
    if (bgRaw is List && bgRaw.length >= 2) {
      bg = bgRaw.map((e) => (e as num).toInt()).toList();
    }

    return StoreItem(
      id: j['slug'] as String,
      title: j['name'] as String,
      subtitle: j['description'] as String?,
      imageUrl: j['image_url'] as String?,
      pricePoints: j['points_cost'] as int,
      category: cat,
      glyph: (j['glyph'] as String?) ?? '🛍',
      background: bg,
    );
  }

  @override
  List<Object?> get props => [id];
}
