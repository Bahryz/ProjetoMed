import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medico_app/core/utils/exceptions.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> registerUser(AppUser user, String password) async {
    UserCredential userCredential;
    try {
      userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: user.email!, password: password);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw EmailAlreadyInUseAuthException();
        case 'weak-password':
          throw WeakPasswordAuthException();
        default:
          throw AuthException(
              'Ocorreu um erro inesperado no registro: ${e.message}');
      }
    }

    try {
      AppUser newUser = user.copyWith(uid: userCredential.user!.uid);
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(newUser.toJson());
    } on FirebaseException catch (e) {
      throw AuthException(
          'Erro ao salvar seus dados. Verifique as regras do Firestore. (Erro: ${e.code})');
    } catch (e) {
      throw AuthException('Ocorreu um erro inesperado ao salvar os dados do usuário.');
    }
  }

  Future<void> loginWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw UserNotFoundAuthException();
        case 'wrong-password':
          throw WrongPasswordAuthException();
        default:
          throw AuthException(
              'Ocorreu um erro inesperado no login: ${e.message}');
      }
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Ocorreu um erro ao enviar o e-mail de redefinição.');
    }
  }

  Future<void> sendSignInLinkToEmail(String email) async {
    var acs = ActionCodeSettings(
      url: 'https://projetomed.page.link/finishSignUp',
      handleCodeInApp: true,
      iOSBundleId: 'com.example.medicoApp',
      androidPackageName: 'com.example.medico_app',
      androidInstallApp: true,
      androidMinimumVersion: '12',
    );
    try {
      await _firebaseAuth.sendSignInLinkToEmail(email: email, actionCodeSettings: acs);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Não foi possível enviar o link de login.');
    }
  }

  Future<AppUser?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromDocumentSnapshot(doc);
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<void> sendEmailVerification() async {
    try {
      if (currentUser != null && !currentUser!.emailVerified) {
        await currentUser!.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Erro ao enviar e-mail de verificação.');
    }
  }

  Future<void> reloadUser() async {
    try {
      await currentUser?.reload();
    } catch (e) {
      print("Erro ao recarregar usuário: $e");
    }
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  Future<UserCredential> signInWithPhoneCredential(AuthCredential credential) async {
    try {
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        throw AuthException('O código de verificação está incorreto.');
      }
      throw AuthException(e.message ?? 'Erro ao verificar o código SMS.');
    }
  }
}