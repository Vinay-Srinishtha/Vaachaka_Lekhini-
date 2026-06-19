class Quote {
  const Quote({
    required this.id,
    this.slug,
    this.text,
    this.source,
    this.textRoman,
    this.sourceRoman,
    this.textTelugu,
    this.sourceTelugu,
    this.textDevanagari,
    this.sourceDevanagari,
    this.textKannada,
    this.sourceKannada,
    this.imageUrl,
    this.mantraId,
  });

  final String id;
  final String? slug;
  final String? text;
  final String? source;
  final String? textRoman;
  final String? sourceRoman;
  final String? textTelugu;
  final String? sourceTelugu;
  final String? textDevanagari;
  final String? sourceDevanagari;
  final String? textKannada;
  final String? sourceKannada;
  final String? imageUrl;
  final String? mantraId;

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        id: json['id'] as String,
        slug: json['slug'] as String?,
        text: json['text'] as String?,
        source: json['source'] as String?,
        textRoman: json['text_roman'] as String?,
        sourceRoman: json['source_roman'] as String?,
        textTelugu: json['text_telugu'] as String?,
        sourceTelugu: json['source_telugu'] as String?,
        textDevanagari: json['text_devanagari'] as String?,
        sourceDevanagari: json['source_devanagari'] as String?,
        textKannada: json['text_kannada'] as String?,
        sourceKannada: json['source_kannada'] as String?,
        imageUrl: json['image_url'] as String?,
        mantraId: json['mantra_id'] as String?,
      );

  /// Returns the best-fit text for a given mantra language code.
  /// Falls back through languages until one is found.
  String? textFor(String? mantraLanguage) {
    switch (mantraLanguage) {
      case 'te':
        return textTelugu ?? textDevanagari ?? textRoman ?? textKannada ?? text;
      case 'hi':
      case 'sa':
        return textDevanagari ?? textRoman ?? textTelugu ?? textKannada ?? text;
      case 'kn':
        return textKannada ?? textTelugu ?? textDevanagari ?? textRoman ?? text;
      default: // 'en', 'roman', or anything else
        return textRoman ?? textDevanagari ?? textTelugu ?? textKannada ?? text;
    }
  }

  /// Returns the best-fit attribution for a given mantra language code.
  String? sourceFor(String? mantraLanguage) {
    switch (mantraLanguage) {
      case 'te':
        return sourceTelugu ?? sourceDevanagari ?? sourceRoman ?? sourceKannada ?? source;
      case 'hi':
      case 'sa':
        return sourceDevanagari ?? sourceRoman ?? sourceTelugu ?? sourceKannada ?? source;
      case 'kn':
        return sourceKannada ?? sourceTelugu ?? sourceDevanagari ?? sourceRoman ?? source;
      default:
        return sourceRoman ?? sourceDevanagari ?? sourceTelugu ?? sourceKannada ?? source;
    }
  }
}
