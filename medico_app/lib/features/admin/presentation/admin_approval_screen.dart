import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medico_app/core/utils/exceptions.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/authentication/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AuthStatus {
  unauthenticated,
  authenticated,
  pendingApproval,
  emailNotVerified,
}

class AuthController with ChangeNotifier {
  final AuthRepository _authRepository;
  late final StreamSubscription<User?> _authStateSubscription;

  AppUser? _appUser;
  AppUser? get user => _appUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _verificationId;
  String? get verificationId => _verificationId;

  AuthStatus get authStatus {
    final user = _authRepository.currentUser;
    if (user == null || _appUser == null) {
      return AuthStatus.unauthenticated;
    }
    // Garante que o status do email está atualizado
    if (!user.emailVerified && _appUser!.userType == 'medico') {
      return AuthStatus.emailNotVerified;
    }
    if (_appUser?.status == 'pendente') {
      return AuthStatus.pendingApproval;
    }
    if (_appUser?.status == 'aprovado') {
      return AuthStatus.authenticated;
    }
    // Caso padrão para paciente ou outros casos
    if (_appUser != null) {
       return AuthStatus.authenticated;
    }
    
    return AuthStatus.unauthenticated;
  }

  AuthController(this._authRepository) {
    _authStateSubscription =
        _authRepository.authStateChanges.listen(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _appUser = null;
    } else {
      await firebaseUser.reload();
      final refreshedUser = _authRepository.currentUser;

      if (refreshedUser != null) {
        final firestoreUser = await _authRepository.getUserData(refreshedUser.uid);
        if (firestoreUser != null) {
          _appUser = firestoreUser.copyWith(
            emailVerified: refreshedUser.emailVerified,
          );
        } else {
          _appUser = null;
        }
      } else {
        _appUser = null;
      }
    }
    notifyListeners();
  }

  Future<bool> handleRegister(AppUser user, String password) async {
    return _handleAuthOperation(() async {
      await _authRepository.registerUser(user, password);
    });
  }

  Future<bool> handleLogin(BuildContext context, String email, String password) async {
    return _handleAuthOperation(() async {
      await _authRepository.loginWithEmailAndPassword(email, password);
    });
  }

  // MÉTODO CORRIGIDO: Renomeado de volta para handleLogout
  Future<void> handleLogout() async {
    await _authRepository.logout();
  }

  Future<bool> sendEmailVerification() async {
    return _handleAuthOperation(() async {
      await _authRepository.sendEmailVerification();
    });
  }

  Future<bool> handlePasswordReset(String email) async {
    return _handleAuthOperation(() async {
      await _authRepository.sendPasswordResetEmail(email);
    });
  }
  
  Future<bool> handleEmailLinkSignIn(String email) async {
    return _handleAuthOperation(() async {
      await _authRepository.sendSignInLinkToEmail(email);
    });
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    await _onAuthStateChanged(_authRepository.currentUser);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> handlePhoneSignIn(BuildContext context, String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _authRepository.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _handleAuthOperation(() async {
          await _authRepository.signInWithPhoneCredential(credential);
        });
      },
      verificationFailed: (FirebaseAuthException e) {
        _errorMessage = e.code == 'invalid-phone-number'
            ? 'O número de telefone fornecido não é válido.'
            : 'Ocorreu um erro ao verificar o telefone: ${e.message}';
        _isLoading = false;
        notifyListeners();
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _isLoading = false;
        context.go('/otp-verify', extra: verificationId);
        notifyListeners();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<bool> handleVerifySmsCode(String smsCode) async {
    if (_verificationId == null) {
      _errorMessage = "ID de verificação não encontrado. Por favor, tente enviar o código novamente.";
      notifyListeners();
      return false;
    }
    
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );
    
    return _handleAuthOperation(() async {
      await _authRepository.signInWithPhoneCredential(credential);
    });
  }

  Future<bool> _handleAuthOperation(Future<void> Function() operation) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await operation();
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
