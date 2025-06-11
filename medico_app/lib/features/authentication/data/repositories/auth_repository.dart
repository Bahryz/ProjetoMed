import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/core/utils/exceptions.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Retorna o usuário logado atualmente, se houver.
  User? get currentUser => _auth.currentUser;

  /// Um stream que notifica sobre mudanças no estado de autenticação (login/logout).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Verifica no Firestore se já existe um usuário com o mesmo e-mail ou telefone.
  /// Isso é crucial para evitar contas duplicadas.
  Future<bool> _checkIfUserExists({String? email, String? phone}) async {
    Query? query;

    // Constrói a query baseada no parâmetro fornecido
    if (email != null && email.isNotEmpty) {
      query = _firestore.collection('users').where('email', isEqualTo: email);
    } else if (phone != null && phone.isNotEmpty) {
      query = _firestore.collection('users').where('telefone', isEqualTo: phone);
    }
    
    // Se nenhum parâmetro foi dado, não há o que checar
    if (query == null) return false;

    final result = await query.limit(1).get();
    return result.docs.isNotEmpty;
  }

  /// Registra um novo usuário com e-mail e senha.
  Future<void> registerUser(AppUser userData, String password) async {
    try {
      // 1. Checa se o e-mail já está em uso no Firestore
      final bool emailExists = await _checkIfUserExists(email: userData.email);
      if (emailExists) {
        throw AuthException("Este endereço de e-mail já está em uso.");
      }

      // 2. Cria o usuário no Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: userData.email!, // O e-mail é obrigatório neste fluxo
        password: password,
      );

      if (userCredential.user != null) {
        // 3. Envia o e-mail de verificação
        await userCredential.user!.sendEmailVerification();

        // 4. Salva as informações do usuário no Firestore
        final userToSave = userData.copyWith(uid: userCredential.user!.uid);
        await _firestore
            .collection('users')
            .doc(userToSave.uid)
            .set(userToSave.toMap());
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw WeakPasswordAuthException();
      } else if (e.code == 'email-already-in-use') {
        throw EmailAlreadyInUseAuthException();
      }
      throw AuthException('Erro ao registrar: ${e.message}');
    } catch (e) {
      throw AuthException(e.toString());
    }
  }
  
  /// Inicia o processo de verificação por telefone.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) onVerificationCompleted,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(String, int?) onCodeSent,
    required Function(String) onCodeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
    );
  }

  /// Efetua o login usando o código SMS recebido.
  Future<UserCredential> signInWithSmsCode(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch(e) {
      if(e.code == "invalid-verification-code"){
        throw AuthException("O código inserido é inválido.");
      }
      throw AuthException("Erro ao verificar o código: ${e.message}");
    }
  }

  /// Realiza o login com e-mail e senha.
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw WrongPasswordAuthException();
      }
      throw AuthException('Erro ao fazer login: ${e.message}');
    } catch (e) {
      throw AuthException('Ocorreu um erro inesperado durante o login.');
    }
  }

  /// Realiza o logout do usuário.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Erro ao fazer logout.');
    }
  }

  /// Envia um e-mail para redefinição de senha.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException('Erro ao enviar e-mail de redefinição: ${e.message}');
    }
  }
}