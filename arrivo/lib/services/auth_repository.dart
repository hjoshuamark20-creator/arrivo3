import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_account.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Auth contract. Swap [LocalAuthRepository] for a backend-based one later.
abstract class AuthRepository {
  Future<UserAccount?> currentUser();
  Future<UserAccount> signUp({required String name, required String email, required String password});
  Future<UserAccount> logIn({required String email, required String password});
  Future<void> logOut();
}

/// Where password hashes live. Production uses the secure keystore; tests use memory.
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureSecretStore implements SecretStore {
  SecureSecretStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Accounts stay on the device: name and email in SharedPreferences,
/// salted SHA-256 password hash in the secure store. No network, no biometrics.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._prefs, this._secrets);

  final SharedPreferences _prefs;
  final SecretStore _secrets;

  static const _accountsKey = 'auth.accounts'; // JSON map: email -> name
  static const _sessionKey = 'auth.session'; // email of the signed-in user
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Map<String, String> _readAccounts() {
    final raw = _prefs.getString(_accountsKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {}
    return {};
  }

  Future<void> _writeAccounts(Map<String, String> accounts) =>
      _prefs.setString(_accountsKey, jsonEncode(accounts));

  String _normalize(String email) => email.trim().toLowerCase();

  String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  String _newSalt() {
    final random = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => random.nextInt(256)));
  }

  /// Compares two strings without stopping at the first difference.
  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  @override
  Future<UserAccount?> currentUser() async {
    final email = _prefs.getString(_sessionKey);
    if (email == null) return null;
    final name = _readAccounts()[email];
    if (name == null) return null;
    return UserAccount(name: name, email: email);
  }

  @override
  Future<UserAccount> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanEmail = _normalize(email);
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw const AuthException('Please enter your name');
    if (!_emailPattern.hasMatch(cleanEmail)) {
      throw const AuthException('Enter a valid email address');
    }
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters');
    }
    final accounts = _readAccounts();
    if (accounts.containsKey(cleanEmail)) {
      throw const AuthException('Account already exists');
    }
    final salt = _newSalt();
    await _secrets.write('pw.$cleanEmail', '$salt:${_hash(salt, password)}');
    accounts[cleanEmail] = cleanName;
    await _writeAccounts(accounts);
    await _prefs.setString(_sessionKey, cleanEmail);
    return UserAccount(name: cleanName, email: cleanEmail);
  }

  @override
  Future<UserAccount> logIn({required String email, required String password}) async {
    final cleanEmail = _normalize(email);
    const wrong = AuthException('Wrong email or password');
    final name = _readAccounts()[cleanEmail];
    final stored = await _secrets.read('pw.$cleanEmail');
    if (name == null || stored == null) throw wrong;
    final split = stored.indexOf(':');
    if (split < 1) throw wrong;
    final salt = stored.substring(0, split);
    final expected = stored.substring(split + 1);
    if (!_constantTimeEquals(expected, _hash(salt, password))) throw wrong;
    await _prefs.setString(_sessionKey, cleanEmail);
    return UserAccount(name: name, email: cleanEmail);
  }

  @override
  Future<void> logOut() async {
    await _prefs.remove(_sessionKey);
  }
}
