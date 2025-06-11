import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  
  AppUser? appUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AuthController(this._repository) {
    _subscription = _repository.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
      appUser = null;
    } else {
      _status = AuthStatus.authenticated;
      _user = user;
      final profileData = await _repository.getUserProfile(user.uid);
      if (profileData != null) {
        appUser = AppUser.fromMap(profileData);
      }
    }
    notifyListeners();
  }

  void checkAuthStatus() {
    _onAuthStateChanged(_repository.currentUser);
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
    await _handleAuthRequest(() => _repository.registerUser(userData, password));
  }

  Future<void> handleLogin(String email, String password) async {
    await _handleAuthRequest(() => _repository.signIn(email, password));
  }
  
  Future<void> handlePhoneSignIn(BuildContext context, String phoneNumber) async {
    await _handleAuthRequest(() async {
      await _repository.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _repository.signInWithSmsCode(credential.verificationId!, credential.smsCode!);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw AuthException(e.message ?? 'Erro na verificação do telefone.');
        },
        onCodeSent: (String verificationId, int? resendToken) {
          if (context.mounted) {
            GoRouter.of(context).push('/verify-otp', extra: verificationId);
          }
        },
        onCodeAutoRetrievalTimeout: (String verificationId) {},
      );
    });
  }

  Future<void> handleOtpVerification(String verificationId, String smsCode) async {
    await _handleAuthRequest(() async {
      await _repository.signInWithSmsCode(verificationId, smsCode);
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