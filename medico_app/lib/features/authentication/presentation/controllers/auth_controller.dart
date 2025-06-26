import 'dart:async';
import 'package:flutter/material.dart';
import 'package:medico_app/core/utils/exceptions.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/authentication/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Enum para representar os diferentes estados de autenticação do usuário.
enum AuthStatus {
  unauthenticated, // Usuário não está logado
  authenticated, // Usuário logado e aprovado
  pendingApproval, // Usuário logado mas aguardando aprovação
  emailNotVerified, // Usuário logado mas com e-mail não verificado
}

/// Gerencia o estado e a lógica de autenticação para a UI.
class AuthController with ChangeNotifier {
  final AuthRepository _authRepository;
  late final StreamSubscription<User?> _authStateSubscription;

  AppUser? _appUser;
  AppUser? get user => _appUser; // Renomeado de 'appUser' para 'user'

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _verificationId;
  String? get verificationId => _verificationId;

  /// Retorna o status atual de autenticação, usado pelo roteador.
  AuthStatus get authStatus {
    final firebaseUser = _authRepository.currentUser;
    if (firebaseUser == null) {
      return AuthStatus.unauthenticated;
    }
    // Habilitando a verificação de e-mail
    if (!firebaseUser.emailVerified) {
       return AuthStatus.emailNotVerified;
    }
    if (_appUser?.status == 'pendente') {
      return AuthStatus.pendingApproval;
    }
    if (_appUser?.status == 'aprovado') {
      return AuthStatus.authenticated;
    }
    // Caso padrão, se o usuário estiver logado no Firebase mas sem dados no Firestore
    return AuthStatus.unauthenticated;
  }

  AuthController(this._authRepository) {
    // Ouve as mudanças no estado de autenticação do Firebase
    _authStateSubscription =
        _authRepository.authStateChanges.listen(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  /// Callback que é acionado sempre que o usuário faz login ou logout.
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _appUser = null;
    } else {
      // Se o usuário estiver logado, busca os dados dele no Firestore.
      _appUser = await _authRepository.getUserData(firebaseUser.uid);
    }
    notifyListeners();
  }

  /// Lida com o processo de registro de um novo usuário.
  Future<bool> handleRegister(AppUser user, String password) async {
    return _handleAuthOperation(() async {
      await _authRepository.registerUser(user, password);
    });
  }

  /// Lida com o processo de login.
  Future<bool> handleLogin(String email, String password) async {
    return _handleAuthOperation(() async {
      await _authRepository.loginWithEmailAndPassword(email, password);
    });
  }

  /// Lida com o processo de logout.
  Future<void> handleLogout() async {
    await _authRepository.logout();
    _appUser = null;
    notifyListeners();
  }

  /// Envia o e-mail de verificação para o usuário logado.
  Future<void> sendEmailVerification() async {
    return _handleAuthOperation(() async {
      await _authRepository.sendEmailVerification();
    });
  }

  /// Verifica o status de autenticação, recarregando o usuário.
  /// Usado na tela de verificação de e-mail para checar se o usuário já confirmou.
  Future<void> checkAuthStatus() async {
    await _authRepository.reloadUser();
    // Força a notificação dos listeners para que a UI (especialmente o GoRouter)
    // reavalie o 'authStatus' com a informação atualizada do usuário.
    notifyListeners();
  }


  /// Lida com o processo de login com telefone (envio de SMS).
  Future<void> handlePhoneSignIn(String phoneNumber) async {
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
        notifyListeners();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  /// Lida com a verificação do código SMS.
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

  /// Função auxiliar para executar operações de autenticação,
  /// gerenciando os estados de 'loading' e 'error' de forma padronizada.
  Future<bool> _handleAuthOperation(Future<void> Function() operation) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await operation();
      _isLoading = false;
      notifyListeners();
      return true; // Sucesso
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false; // Falha
    }
  }
}
