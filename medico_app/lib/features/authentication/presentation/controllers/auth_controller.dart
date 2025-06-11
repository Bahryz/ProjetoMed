import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medico_app/core/utils/exceptions.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/authentication/data/repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthController with ChangeNotifier {
  final AuthRepository _repository;
  late StreamSubscription<User?> _subscription;

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get authStatus => _status;

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AuthController(this._repository) {
    _subscription = _repository.authStateChanges.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) {
    if (user == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
    } else {
      _status = AuthStatus.authenticated;
      _user = user;
    }
    notifyListeners();
  }

  // NOVO MÉTODO 1: PARA VERIFICAR O STATUS APÓS O USUÁRIO ATUALIZAR O E-MAIL
  void checkAuthStatus() {
    _onAuthStateChanged(_repository.currentUser);
  }

  Future<void> _handleAuthRequest(Future<void> Function() request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await request();
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> handleRegister(AppUser userData, String password) async {
    await _handleAuthRequest(() => _repository.registerUser(userData, password));
  }

  Future<void> handleLogin(String email, String password) async {
    await _handleAuthRequest(() => _repository.signIn(email, password));
  }

  // NOVO MÉTODO 2: PARA FAZER LOGOUT
  Future<void> handleLogout() async {
    await _repository.signOut();
  }

  Future<void> handlePasswordReset(String email) async {
    try {
      await _repository.sendPasswordResetEmail(email);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}