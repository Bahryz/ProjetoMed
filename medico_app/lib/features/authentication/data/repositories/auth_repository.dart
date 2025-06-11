import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/core/utils/exceptions.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final docSnapshot = await _firestore.collection('users').doc(uid).get();
    return docSnapshot.data();
  }

  Future<bool> _checkIfUserExists({String? email, String? phone}) async {
    if (email == null && phone == null) return false;
    Query query = _firestore.collection('users');
    if (email != null && email.isNotEmpty) {
      query = query.where('email', isEqualTo: email);
    } else if (phone != null && phone.isNotEmpty) {
      query = query.where('telefone', isEqualTo: phone);
    }
    final result = await query.limit(1).get();
    return result.docs.isNotEmpty;
  }

  Future<void> registerUser(AppUser userData, String password) async {
    try {
      final bool emailExists = await _checkIfUserExists(email: userData.email);
      if (emailExists) {
        throw AuthException("Este endereço de e-mail já está em uso.");
      }
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: userData.email!,
        password: password,
      );
      if (userCredential.user != null) {
        await userCredential.user!.sendEmailVerification();
        final userToSave = userData.copyWith(uid: userCredential.user!.uid);
        await _firestore.collection('users').doc(userToSave.uid).set(userToSave.toMap());
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') throw WeakPasswordAuthException();
      if (e.code == 'email-already-in-use') throw EmailAlreadyInUseAuthException();
      throw AuthException('Erro ao registrar: ${e.message}');
    } catch (e) {
      throw AuthException('Ocorreu um erro inesperado durante o registro.');
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (['user-not-found', 'wrong-password', 'invalid-credential'].contains(e.code)) {
        throw WrongPasswordAuthException();
      }
      throw AuthException('Erro ao fazer login: ${e.message}');
    } catch (e) {
      throw AuthException('Ocorreu um erro inesperado durante o login.');
    }
  }

   Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  Future<UserCredential> signInWithSmsCode(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}