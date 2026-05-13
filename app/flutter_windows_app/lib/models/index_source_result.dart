class IndexSourceResult {
  const IndexSourceResult({
    required this.indexed,
    required this.skipped,
    required this.failed,
    required this.empty,
    required this.total,
  });

  final int indexed;
  final int skipped;
  final int failed;
  final int empty;
  final int total;

  factory IndexSourceResult.fromJson(Map<String, dynamic> json) {
    return IndexSourceResult(
      indexed: json['indexed'] as int,
      skipped: json['skipped'] as int,
      failed: json['failed'] as int,
      empty: json['empty'] as int,
      total: json['total'] as int,
    );
  }

  String get summary {
    return '$indexed indexed, $skipped skipped, $empty empty, $failed failed';
  }
}
