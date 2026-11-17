import 'package:friend_professional/l10n/tr.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the Akilil Pro app is currently locked (requires re-auth).
///
/// Locking happens automatically when the therapist leaves/backgrounds the app,
/// protecting sensitive HIPAA client health data.
/// Unlock happens via biometric (Face ID / fingerprint) or password re-entry.
class AppLockController extends StateNotifier<bool> {
  AppLockController() : super(false) {
    _init();
  }

  final _auth = LocalAuthentication();
  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  bool _initialized = false;
  bool _biometricsAvailable = false;
  bool get biometricsAvailable => _biometricsAvailable;

  bool _biometricEnabled = true;
  bool get biometricEnabled => _biometricEnabled;

  static const _kPrefBioEnabled = 'pro_biometric_lock_enabled';
  static const _kSecBioEmail = 'akilil_pro_bio_email';
  static const _kSecBioPassword = 'akilil_pro_bio_password';

  Future<void> _init() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      _biometricsAvailable = canCheck || isSupported;
    } catch (_) {
      _biometricsAvailable = false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _biometricEnabled = prefs.getBool(_kPrefBioEnabled) ?? true;
    } catch (_) {
      _biometricEnabled = true;
    }

    _initialized = true;
  }

  Future<void> ensureInitialized() async {
    if (!_initialized) {
      await _init();
    }
  }

  /// Called when app goes to background — locks the clinical session immediately.
  void lock() {
    if (state) return;
    state = true;
  }

  /// Attempt biometric unlock. Returns true if successful.
  Future<bool> unlockWithBiometrics() async {
    await ensureInitialized();
    if (!_biometricsAvailable || !_biometricEnabled) return false;
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: tr('Scan face or fingerprint to unlock Akilil Pro clinical workspace'),
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (authenticated) {
        state = false;
      }
      return authenticated;
    } catch (_) {
      return false;
    }
  }

  /// Called after successful password re-entry.
  void unlockWithPassword() => state = false;

  /// Toggle biometric lock preference.
  Future<void> setBiometricEnabled({required bool enabled}) async {
    _biometricEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPrefBioEnabled, enabled);
    } catch (_) {}
  }

  /// Store credentials securely for 1-tap biometric login.
  Future<void> saveBiometricCredentials({
    required String email,
    required String password,
  }) async {
    try {
      await _secure.write(key: _kSecBioEmail, value: email);
      await _secure.write(key: _kSecBioPassword, value: password);
    } catch (_) {}
  }

  /// Check whether credentials exist for biometric login.
  Future<bool> hasSavedBiometricCredentials() async {
    try {
      final email = await _secure.read(key: _kSecBioEmail);
      final pass = await _secure.read(key: _kSecBioPassword);
      return email != null && email.isNotEmpty && pass != null && pass.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Retrieve saved biometric login credentials.
  Future<({String email, String password})?> getSavedBiometricCredentials() async {
    try {
      final email = await _secure.read(key: _kSecBioEmail);
      final pass = await _secure.read(key: _kSecBioPassword);
      if (email != null && email.isNotEmpty && pass != null && pass.isNotEmpty) {
        return (email: email, password: pass);
      }
    } catch (_) {}
    return null;
  }

  /// Clear saved biometric credentials.
  Future<void> clearSavedBiometricCredentials() async {
    try {
      await _secure.delete(key: _kSecBioEmail);
      await _secure.delete(key: _kSecBioPassword);
    } catch (_) {}
  }
}

final appLockProvider =
    StateNotifierProvider<AppLockController, bool>((_) => AppLockController());
