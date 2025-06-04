import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';


class AuthController extends ChangeNotifier {
  final AuthRepository _repository;
  AuthController(this._repository);

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> _handleAuthRequest(Future<void> Function() request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await request();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> handleSignIn(String email, String password) async {
    return _handleAuthRequest(() => _repository.signIn(email: email, password: password));
  }
  
  // Adicione aqui os handlers para registro de médico e paciente...
}