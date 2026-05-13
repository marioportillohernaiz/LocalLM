import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_response.dart';
import '../models/chat_history_item.dart';
import '../models/index_source_result.dart';
import '../models/model_catalog_item.dart';
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

  Future<IndexSourceResult> indexSource(
    int sourceId, {
    String? embeddingModel,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sources/$sourceId/index'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (embeddingModel != null && embeddingModel.trim().isNotEmpty)
          'embedding_model': embeddingModel.trim(),
      }),
    );
    _throwIfNotOk(response, 'Failed to index source');

    return IndexSourceResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ChatResponse> ask({
    required String question,
    required List<String> labels,
    String? llmModel,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/ask'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'question': question,
        'labels': labels,
        if (llmModel != null && llmModel.trim().isNotEmpty)
          'llm_model': llmModel.trim(),
      }),
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

  Future<List<String>> getModels() async {
    final data = await _getModelPayload();
    return _readModelList(data, 'models');
  }

  Future<List<String>> getChatModels() async {
    final data = await _getModelPayload();
    return _readModelList(data, 'chat_models');
  }

  Future<List<String>> getEmbeddingModels() async {
    final data = await _getModelPayload();
    return _readModelList(data, 'embedding_models');
  }

  Future<List<ModelCatalogItem>> getModelCatalog() async {
    final response = await http.get(Uri.parse('$baseUrl/models/catalog'));
    _throwIfNotOk(response, 'Failed to load model catalog');

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => ModelCatalogItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> pullModel(String model) async {
    final response = await http.post(
      Uri.parse('$baseUrl/models/pull'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'model': model}),
    );
    _throwIfNotOk(response, 'Failed to download model');
  }

  Future<void> deleteHistoryItem(int historyId) async {
    final response =
        await http.delete(Uri.parse('$baseUrl/history/$historyId'));
    _throwIfNotOk(response, 'Failed to delete history item');
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

  Future<Map<String, dynamic>> _getModelPayload() async {
    final response = await http.get(Uri.parse('$baseUrl/models'));
    _throwIfNotOk(response, 'Failed to load models');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  List<String> _readModelList(Map<String, dynamic> data, String key) {
    final models = data[key];
    if (models is! List<dynamic>) {
      return [];
    }
    return models.whereType<String>().toList();
  }
}
