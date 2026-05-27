class Source {
  const Source({
    required this.id,
    required this.label,
    required this.path,
    required this.createdAt,
    this.lastIndexedAt,
    this.embeddingModel,
  });

  final int id;
  final String label;
  final String path;
  final DateTime createdAt;
  final DateTime? lastIndexedAt;
  final String? embeddingModel;

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      id: json['id'] as int,
      label: json['label'] as String,
      path: json['path'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastIndexedAt: json['last_indexed_at'] == null
          ? null
          : DateTime.parse(json['last_indexed_at'] as String),
      embeddingModel: json['embedding_model'] as String?,
    );
  }
}
