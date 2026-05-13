class ModelCatalogItem {
  const ModelCatalogItem({
    required this.name,
    required this.displayName,
    required this.kind,
    required this.sizeLabel,
    required this.approximateSize,
    required this.description,
    required this.installed,
  });

  final String name;
  final String displayName;
  final String kind;
  final String sizeLabel;
  final String approximateSize;
  final String description;
  final bool installed;

  factory ModelCatalogItem.fromJson(Map<String, dynamic> json) {
    return ModelCatalogItem(
      name: json['name'] as String,
      displayName: json['display_name'] as String,
      kind: json['kind'] as String,
      sizeLabel: json['size_label'] as String,
      approximateSize: json['approximate_size'] as String,
      description: json['description'] as String,
      installed: json['installed'] as bool,
    );
  }
}
