import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

final apiBaseUrlProvider = StateProvider<String>(
  (ref) => 'http://127.0.0.1:8000',
);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: ref.watch(apiBaseUrlProvider));
});
