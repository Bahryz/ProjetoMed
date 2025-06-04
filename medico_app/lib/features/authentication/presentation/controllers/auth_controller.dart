// lib/features/authentication/presentation/controllers/auth_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- IMPORT ADICIONADO
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/authentication/data/repositories/auth_repository.dart';
import 'package:medico_app/core/utils/exceptions.dart'; // Importe suas exceções

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthController with ChangeNotifier {
  final AuthRepository _repository;
  late StreamSubscription<User?> _authStateSubscription; // Agora User é reconhecido

  AuthController(this._repository) {
    // Ouça as mudanças no estado de autenticação do repositório
    _authStateSubscription = _repository.authStateChanges.listen(_onAuthStateChanged);
    // Verifique o estado inicial
    _onAuthStateChanged(_repository.currentUser);
  }

  AuthStatus _status = AuthStatus.unknown;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _onAuthStateChanged(User? user) { // Agora User é reconhecido
    if (user == null) {
      _status = AuthStatus.unauthenticated;
    } else {
      _status = AuthStatus.authenticated;
    }
    notifyListeners(); // Notifica GoRouter e outros ouvintes
  }

  Future<bool> _handleAuthRequest(Future<void> Function() request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await request();
      // O status será atualizado pelo _onAuthStateChanged
      return true;
    } on AuthException catch (e) { // Captura nossas exceções personalizadas
      _errorMessage = e.message;
      return false;
    } catch (e) { // Captura qualquer outra exceção genérica
      _errorMessage = 'Ocorreu um erro inesperado: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> handleSignIn(String email, String password) async {
    // CORRIGIDO: signIn espera argumentos posicionais
    return _handleAuthRequest(() => _repository.signIn(email, password));
  }

  Future<bool> handleRegister(AppUser userData, String password) async {
    return _handleAuthRequest(() => _repository.registerUser(userData, password));
  }
  
  Future<void> handleSignOut() async {
    await _repository.signOut();
    // O status será atualizado pelo _onAuthStateChanged
  }

  @override
  void dispose() {
    _authStateSubscription.cancel(); // Cancela a inscrição ao stream
    super.dispose();
  }
}