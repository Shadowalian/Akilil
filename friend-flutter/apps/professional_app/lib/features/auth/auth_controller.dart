import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core/core.dart';

/// Authenticated user shape for the pro app. Same wire format as the
/// user app, since both share the same /api/auth/* and /api/me routes.
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
  final String role;
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
  bool get isProfessional => role == 'professional';
  bool get needsOnboarding => role == 'professional' && totpEnabled == false;
}

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
  bool get isProfessional => _user?.isProfessional == true;

  TokenStorage get _storage => _ref.read(tokenStorageProvider);
  Dio get _dio => _ref.read(dioProvider);

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
      await _storage.clear();
    } finally {
      _bootstrapping = false;
      notifyListeners();
    }
  }

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
    AuthUser user;
    final embedded = data['user'];
    if (embedded is Map) {
      user = AuthUser.fromJson(Map<String, dynamic>.from(embedded));
    } else {
      final me = await _dio.get<Map<String, dynamic>>(
        '/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      user = AuthUser.fromJson(me.data!);
    }
    if (!user.isProfessional) {
      await _storage.clear();
      throw StateError('This account is not a professional. Use the client app.');
    }
    _user = user;
    notifyListeners();
  }

  Future<void> registerProfessional({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/register-professional',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
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
    _user = AuthUser.fromJson(me.data!);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    await _storage.clear();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshMe() async {
    final me = await _dio.get<Map<String, dynamic>>('/me');
    _user = AuthUser.fromJson(me.data!);
    notifyListeners();
  }
}

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(ref);
});

final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authControllerProvider).user;
});