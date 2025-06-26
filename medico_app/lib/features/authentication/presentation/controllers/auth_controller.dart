import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medico_app/core/utils/exceptions.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/authentication/data/repositories/auth_repository.dart';

// 1. ADICIONADO NOVO STATUS PARA CONTROLE DE APROVAÇÃO
enum AuthStatus { unknown, authenticated, unauthenticated, pendingApproval }

class AuthController with ChangeNotifier {
  final AuthRepository _repository;
  late StreamSubscription<User?> _subscription;

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get authStatus => _status;

  User? _user;
  User? get user => _user;
  
  AppUser? appUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AuthController(this._repository) {
    _subscription = _repository.authStateChanges.listen(_onAuthStateChanged);
  }

  bool _requiresTwoFactor = false;

  // 2. LÓGICA DE VERIFICAÇÃO CENTRALIZADA
  /// Este método agora verifica o status do médico e define o AuthStatus apropriado.
  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
      appUser = null;
      _requiresTwoFactor = false;
    } else {
      // Se não estivermos no meio de um fluxo de 2FA, verifique o status.
      if (!_requiresTwoFactor) {
        final profileData = await _repository.getUserProfile(user.uid);
        if (profileData != null) {
          appUser = AppUser.fromMap(profileData);
          _user = user;

          // Se for médico, verifique o status de aprovação.
          if (appUser!.userType == 'medico' && appUser!.status != 'aprovado') {
            _status = AuthStatus.pendingApproval;
          } else {
            _status = AuthStatus.authenticated;
          }
        } else {
          // Perfil não encontrado, deslogar para evitar estado inconsistente.
          await handleLogout();
          _errorMessage = "Perfil de usuário não encontrado.";
        }
      }
    }
    notifyListeners();
  }

  void checkAuthStatus() {
    _onAuthStateChanged(_repository.currentUser);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _handleAuthRequest(Future<void> Function() request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await request();
      _errorMessage = null; 
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> handleRegister(AppUser userData, String password) async {
    // Após o registro, _onAuthStateChanged será chamado e fará a verificação de status.
    await _handleAuthRequest(() => _repository.registerUser(userData, password));
  }

  // 3. LÓGICA DE LOGIN AJUSTADA
  /// O método agora checa o status do médico antes de iniciar o fluxo de 2FA.
  Future<void> handleLogin(BuildContext context, String email, String password) async {
    await _handleAuthRequest(() async {
      await _repository.signIn(email, password);
      final currentUser = _repository.currentUser;
      if (currentUser != null) {
        final userProfileMap = await _repository.getUserProfile(currentUser.uid);
        if (userProfileMap != null) {
          final userDetails = AppUser.fromMap(userProfileMap);
          
          // Se for um médico pendente, o _onAuthStateChanged já terá definido o
          // status como pendingApproval. O router deve tratar o redirecionamento.
          // Aqui, apenas evitamos o fluxo de 2FA para ele.
          if (userDetails.userType == 'medico' && userDetails.status != 'aprovado') {
             _onAuthStateChanged(currentUser); // Força a atualização de estado
             return; // Interrompe o fluxo para 2FA
          }

          // Para pacientes ou médicos aprovados, inicia o fluxo de 2FA.
          _requiresTwoFactor = true;
          if (context.mounted) {
            context.go('/two-factor-auth', extra: userDetails);
          }
        } else {
          await handleLogout();
          throw AuthException("Perfil do usuário não encontrado no banco de dados.");
        }
      } else {
        throw AuthException("Ocorreu um erro inesperado durante o login.");
      }
    });
  }
  
  Future<void> handlePhoneSignIn(BuildContext context, String phoneNumber) async {
    await _handleAuthRequest(() async {
      await _repository.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _repository.signInWithSmsCode(credential.verificationId!, credential.smsCode!);
          _requiresTwoFactor = false;
          notifyListeners();
        },
        verificationFailed: (FirebaseAuthException e) {
          throw AuthException(e.message ?? 'Erro na verificação do telefone.');
        },
        codeSent: (String verificationId, int? resendToken) {
          if (context.mounted) {
            GoRouter.of(context).push('/verify-otp', extra: verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    });
  }

  Future<void> handleEmailLinkSignIn(BuildContext context, String email) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("A funcionalidade de link por e-mail ainda não foi implementada."),
        backgroundColor: Colors.amber,
      ),
    );
  }

  Future<void> handleOtpVerification(String verificationId, String smsCode) async {
    await _handleAuthRequest(() async {
      await _repository.signInWithSmsCode(verificationId, smsCode);
      _requiresTwoFactor = false;
      _onAuthStateChanged(_repository.currentUser); // Reavalia o estado de auth
    });
  }

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
