import 'chat_response.dart';

class ChatHistoryItem {
  const ChatHistoryItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.labels,
    required this.sources,
    required this.createdAt,
  });

  final int id;
  final String question;
  final String answer;
  final List<String> labels;
  final List<ChatSource> sources;
  final DateTime createdAt;

  factory ChatHistoryItem.fromJson(Map<String, dynamic> json) {
    return ChatHistoryItem(
      id: json['id'] as int,
      question: json['question'] as String,
      answer: json['answer'] as String,
      labels: (json['labels'] as List<dynamic>).cast<String>(),
      sources: (json['sources'] as List<dynamic>)
          .map((item) => ChatSource.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  ChatResponse toChatResponse() {
    return ChatResponse(question: question, answer: answer, sources: sources);
  }
}
