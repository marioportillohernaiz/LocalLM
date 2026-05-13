class ChatSource {
  const ChatSource({
    required this.fileName,
    required this.filePath,
    required this.chunkText,
  });

  final String fileName;
  final String filePath;
  final String chunkText;

  factory ChatSource.fromJson(Map<String, dynamic> json) {
    return ChatSource(
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      chunkText: json['chunk_text'] as String,
    );
  }
}

class ChatResponse {
  const ChatResponse({
    required this.question,
    required this.answer,
    required this.sources,
  });

  final String question;
  final String answer;
  final List<ChatSource> sources;

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      question: json['question'] as String,
      answer: json['answer'] as String,
      sources: (json['sources'] as List<dynamic>)
          .map((item) => ChatSource.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
