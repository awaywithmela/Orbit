import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_database.dart';
import '../domain/user_profile.dart';
import 'auth_state.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  static const _usersKey = 'auth.users';
  static const _sessionKey = 'auth.session';

  @override
  AuthState build() {
    Future.microtask(() async {
      await _ensureDemoAccount();
      await _restoreSession();
    });
    return const AuthState.signedOut();
  }

  void clearError() => state = state.copyWith(clearError: true);

  Future<void> signInWithProfile({
    required String displayName,
    required String email,
    required String currencyCode,
    DateTime? birthDate,
    String password = '',
    String confirmPassword = '',
    bool isLoginMode = false,
  }) async {
    final name = displayName.trim();
    final address = email.trim().toLowerCase();
    final secret = password.trim();
    if (!isLoginMode && name.isEmpty) return _error('Please add your name to create an account.');
    if (!address.contains('@')) return _error('Please enter a valid email.');
    if (secret.isEmpty) return _error('Please enter your password.');
    if (!isLoginMode && secret.length < 8) return _error('Use at least 8 characters for your password.');
    if (!isLoginMode && secret != confirmPassword.trim()) return _error('Passwords do not match.');

    // The demo account is created asynchronously during provider startup. Make
    // login deterministic even if the user taps Log In immediately, without
    // delaying synchronous signup validation.
    if (isLoginMode) await _ensureDemoAccount();

    state = state.copyWith(isLoading: true, clearError: true);
    final users = await _users();
    final existing = users[address];
    if (isLoginMode) {
      if (existing == null || existing['password'] != secret) {
        return _error('Incorrect email or password. Check both fields and try again.');
      }
    } else if (existing != null) {
      return _error('An account already exists for this email. Choose Log In instead.');
    }
    final profile = UserProfile(
      id: existing?['id']?.toString() ?? _idFor(address),
      displayName: isLoginMode ? existing['displayName'].toString() : name,
      email: address,
      currencyCode: isLoginMode ? existing['currencyCode'].toString() : currencyCode,
      birthDate: isLoginMode
          ? DateTime.tryParse(existing['birthDate']?.toString() ?? '')
          : birthDate,
    );
    users[address] = {'password': secret, ..._profileJson(profile)};
    await _saveUsers(users);
    await LocalDatabase.instance.write(_sessionKey, profile.id);
    state = AuthState(profile: profile, isLoading: false, errorMessage: null);
  }

  Future<void> updateProfile(UserProfile profile) async {
    final users = await _users();
    final key = profile.email.toLowerCase();
    final user = users[key];
    if (user == null) return;
    users[key] = {...user, ..._profileJson(profile)};
    await _saveUsers(users);
    state = state.copyWith(profile: profile, clearError: true);
  }

  Future<void> signOut() async {
    await LocalDatabase.instance.delete(_sessionKey);
    state = const AuthState.signedOut();
  }

  Future<void> resendConfirmation(String email) async {
    state = state.copyWith(errorMessage: 'Email confirmation is not required for local accounts. You can log in immediately.');
  }

  Future<void> _restoreSession() async {
    final id = await LocalDatabase.instance.read(_sessionKey);
    if (id == null) return;
    final users = await _users();
    for (final user in users.values) {
      if (user['id'] == id) {
        state = AuthState(profile: _profileFrom(user), isLoading: false, errorMessage: null);
        return;
      }
    }
  }

  Future<void> _ensureDemoAccount() async {
    final users = await _users();
    const email = 'demo@orbit.local';
    if (users.containsKey(email)) return;
    users[email] = {
      'password': 'OrbitDemo123!',
      'id': 'local-demo',
      'displayName': 'Orbit Demo',
      'email': email,
      'currencyCode': 'PHP',
      'birthDate': null,
    };
    await _saveUsers(users);
  }

  Future<Map<String, dynamic>> _users() async {
    final raw = await LocalDatabase.instance.read(_usersKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw);
    return decoded is Map ? decoded.map((key, value) => MapEntry(key.toString(), Map<String, dynamic>.from(value as Map))) : {};
  }

  Future<void> _saveUsers(Map<String, dynamic> users) => LocalDatabase.instance.write(_usersKey, jsonEncode(users));

  void _error(String message) => state = state.copyWith(isLoading: false, errorMessage: message);

  static String _idFor(String email) => 'local-${email.hashCode.abs()}';

  static Map<String, dynamic> _profileJson(UserProfile profile) => {
    'id': profile.id,
    'displayName': profile.displayName,
    'email': profile.email,
    'currencyCode': profile.currencyCode,
    'birthDate': profile.birthDate?.toIso8601String(),
  };

  static UserProfile _profileFrom(Map<String, dynamic> user) => UserProfile(
    id: user['id'].toString(),
    displayName: user['displayName'].toString(),
    email: user['email'].toString(),
    currencyCode: user['currencyCode'].toString(),
    birthDate: DateTime.tryParse(user['birthDate']?.toString() ?? ''),
  );
}
