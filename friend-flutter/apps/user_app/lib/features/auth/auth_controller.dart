import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core/core.dart';

/// Authenticated user shape — what `/api/me` returns.
/// Minimal fields used by the app; full profile is fetched on demand.
@immutable
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.totpEnabled,
    required this.totpConfirmed,
  });

  final int id;
  final String name;
  final String email;
  final String role;            // 'user' | 'professional'
  final bool totpEnabled;
  final bool totpConfirmed;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final map = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    return AuthUser(
      id: (map['id'] as num).toInt(),
      name: (map['name'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      role: (map['role'] ?? 'user') as String,
      totpEnabled:
          (map['totp_enabled'] ?? map['two_factor_enabled'] ?? false) == true,
      totpConfirmed: map['totp_confirmed_at'] != null,
    );
  }

  bool get needs2FASetup => totpEnabled && !totpConfirmed;
}

/// AuthController owns the auth lifecycle. It's a Listenable (via
/// ChangeNotifier) so the go_router's `refreshListenable` can react
/// to login/logout events.
class AuthController extends ChangeNotifier {
  AuthController(this._ref) {
    _bootstrap();
  }

  final Ref _ref;
  AuthUser? _user;
  bool _bootstrapping = true;

  AuthUser? get user => _user;
  bool get isBootstrapping => _bootstrapping;
  bool? get isAuthenticated => _bootstrapping ? null : _user != null;
  bool get mustSetup2FA => _user?.needs2FASetup == true;

  TokenStorage get _storage => _ref.read(tokenStorageProvider);
  Dio get _dio => _ref.read(dioProvider);

  /// On app start: if we have a token, try `/api/me`. If the call
  /// fails (401, network), we drop the token. If no token, we stay logged out.
  Future<void> _bootstrap() async {
    try {
      final token = await _storage.read();
      if (token == null || token.isEmpty) {
        _bootstrapping = false;
        notifyListeners();
        return;
      }
      final res = await _dio.get<Map<String, dynamic>>('/me');
      if (res.statusCode == 200 && res.data != null) {
        _user = AuthUser.fromJson(res.data!);
      } else {
        await _storage.clear();
      }
    } on DioException {
      // Network or 401 — clear token so the user lands on the login page.
      await _storage.clear();
    } on Object {
      // Bad /me payload shape — don't leave the app stuck mid-bootstrap.
      await _storage.clear();
    } finally {
      _bootstrapping = false;
      notifyListeners();
    }
  }

  /// `POST /api/auth/login` — server returns token + user; use that so we
  /// don't depend on a slow/wrapping `/me` round-trip to finish sign-in.
  Future<void> login({required String email, required String password}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = res.data ?? const {};
    if (data['requires_2fa'] == true) {
      throw StateError('Two-factor login is not supported in this build yet.');
    }
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw StateError('Login response missing token');
    }
    try {
      await _storage.write(token);
    } catch (_) {/* memory token still set inside TokenStorage */}
    final embedded = data['user'];
    if (embedded is Map) {
      _user = AuthUser.fromJson(Map<String, dynamic>.from(embedded));
      notifyListeners();
      return;
    }
    final me = await _dio.get<Map<String, dynamic>>(
      '/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (me.data == null) {
      throw StateError('Could not load your profile after login.');
    }
    _user = AuthUser.fromJson(me.data!);
    notifyListeners();
  }

  /// `POST /api/auth/register` — same token+user envelope as login.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required DateTime dateOfBirth,
    String seekingCareFor = 'self',
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'date_of_birth': dateOfBirth.toIso8601String().substring(0, 10),
        'seeking_care_for': seekingCareFor,
        'accept_terms': true,
      },
    );
    final data = res.data ?? const {};
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw StateError('Register response missing token');
    }
    try {
      await _storage.write(token);
    } catch (_) {/* memory token still set */}
    final embedded = data['user'];
    if (embedded is Map) {
      _user = AuthUser.fromJson(Map<String, dynamic>.from(embedded));
      notifyListeners();
      return;
    }
    final me = await _dio.get<Map<String, dynamic>>(
      '/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (me.data == null) {
      throw StateError('Could not load your profile after registration.');
    }
    _user = AuthUser.fromJson(me.data!);
    notifyListeners();
  }

  /// `POST /api/auth/logout` — revokes the current token server-side.
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {/* swallow — we always clear local state */}
    await _storage.clear();
    _user = null;
    notifyListeners();
  }

  /// After the user confirms TOTP on the setup page, refresh `/me` so
  /// `mustSetup2FA` flips to false and the router pushes them to home.
  Future<void> refreshMe() async {
    final me = await _dio.get<Map<String, dynamic>>('/me');
    _user = AuthUser.fromJson(me.data!);
    notifyListeners();
  }

  /// Re-fetch `/me` after a profile edit.
  Future<void> refreshUser() => refreshMe();
}

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(ref);
});

/// Convenience read of the current user; throws while bootstrapping.
final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authControllerProvider).user;
});