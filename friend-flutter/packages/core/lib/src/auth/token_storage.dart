import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for the Sanctum API token returned by POST /api/auth/login.
///
/// Keeps an in-memory copy so the Dio interceptor can attach the Bearer token
/// immediately after login — on web, [FlutterSecureStorage.write] can lag behind
/// the follow-up `/me` request and cause a false "login failed".
///
/// Override [FRIEND_TOKEN_NAMESPACE] so user + pro apps on the same origin
/// do not share one token (e.g. `--dart-define=FRIEND_TOKEN_NAMESPACE=pro`).
const _tokenNamespace =
    String.fromEnvironment('FRIEND_TOKEN_NAMESPACE', defaultValue: 'Akilil');

String get _tokenKey => '${_tokenNamespace}_sanctum_token';

class TokenStorage {
  TokenStorage(this._secure);

  final FlutterSecureStorage _secure;

  /// Synchronous cache — updated on every write/clear.
  String? _memory;

  String? get memory => _memory;

  Future<String?> read() async {
    if (_memory != null && _memory!.isNotEmpty) return _memory;
    _memory = await _secure.read(key: _tokenKey);
    return _memory;
  }

  Future<void> write(String token) async {
    _memory = token;
    try {
      await _secure.write(key: _tokenKey, value: token);
    } catch (_) {
      // Web IndexedDB / secure storage can fail; memory token still works
      // for the rest of this session via the Dio interceptor.
    }
  }

  Future<void> clear() async {
    _memory = null;
    try {
      await _secure.delete(key: _tokenKey);
    } catch (_) {/* ignore */}
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(
    FlutterSecureStorage(
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
      webOptions: WebOptions(
        dbName: '${_tokenNamespace}_secure',
        publicKey: '${_tokenNamespace}_sanctum',
      ),
    ),
  );
});
