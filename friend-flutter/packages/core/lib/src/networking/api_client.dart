import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_storage.dart';

/// Akilil API base URL — overridable via --dart-define for local/staging.
/// Default is the live Akilil deploy so release APKs work on real devices.
const _envBaseUrl = String.fromEnvironment('FRIEND_API_BASE_URL');
const _liveApiBaseUrl = 'http://13.140.131.249/api';

String resolveApiBaseUrl() {
  if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
  return _liveApiBaseUrl;
}

/// Single shared Dio instance configured with:
///   - base URL (override at build time)
///   - JSON content negotiation
///   - Sanctum Bearer token via interceptor
///   - structured error logging (Task 4 wires Sentry; this is dev fallback)
///   - 30s timeout
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final dio = Dio(BaseOptions(
    baseUrl: resolveApiBaseUrl(),
    connectTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  // Bearer token interceptor — runs on every request.
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token =
          ref.read(tokenStorageProvider).memory ?? await storage.read();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
  ));

  return dio;
});
