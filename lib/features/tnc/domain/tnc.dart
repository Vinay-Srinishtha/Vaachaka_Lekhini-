class TermsAndConditions {
  const TermsAndConditions({
    required this.id,
    required this.version,
    required this.title,
    required this.content,
    required this.isActive,
    required this.effectiveAt,
  });

  final String id;
  final String version;
  final String title;
  final String content;
  final bool isActive;
  final DateTime effectiveAt;

  factory TermsAndConditions.fromJson(Map<String, dynamic> j) =>
      TermsAndConditions(
        id: j['id'] as String,
        version: j['version'] as String,
        title: j['title'] as String,
        content: j['content'] as String,
        isActive: j['is_active'] as bool? ?? false,
        effectiveAt: DateTime.tryParse(j['effective_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
