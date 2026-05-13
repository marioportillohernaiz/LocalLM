import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_response.dart';
import '../models/chat_history_item.dart';
import '../models/index_source_result.dart';
import '../models/source.dart';

class ApiClient {
  ApiClient({this.baseUrl = 'http://127.0.0.1:8000'});

  final String baseUrl;

  Future<List<Source>> getSources() async {
    final response = await http.get(Uri.parse('$baseUrl/sources'));
    _throwIfNotOk(response, 'Failed to load sources');

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Source.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Source> addSource({
    required String label,
    required String path,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sources'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'label': label, 'path': path}),
    );
    _throwIfNotOk(response, 'Failed to add source');

    return Source.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<IndexSourceResult> indexSource(int sourceId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sources/$sourceId/index'),
    );
    _throwIfNotOk(response, 'Failed to index source');

    return IndexSourceResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ChatResponse> ask({
    required String question,
    required List<String> labels,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/ask'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'question': question, 'labels': labels}),
    );
    _throwIfNotOk(response, 'Failed to ask question');

    return ChatResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<ChatHistoryItem>> getHistory() async {
    final response = await http.get(Uri.parse('$baseUrl/history'));
    _throwIfNotOk(response, 'Failed to load history');

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => ChatHistoryItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  void _throwIfNotOk(http.Response response, String fallbackMessage) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String? detailMessage;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = body['detail'];
      if (detail is String && detail.isNotEmpty) {
        detailMessage = detail;
      } else if (detail is Map<String, dynamic>) {
        final message = detail['message'];
        final hint = detail['hint'];
        if (message is String && message.isNotEmpty) {
          detailMessage = message;
          if (hint is String && hint.isNotEmpty) {
            detailMessage = '$detailMessage\n$hint';
          }
        }
      }
    } catch (_) {
      detailMessage = null;
    }

    if (detailMessage != null) {
      throw Exception(detailMessage);
    }

    throw Exception('$fallbackMessage (${response.statusCode})');
  }
}
