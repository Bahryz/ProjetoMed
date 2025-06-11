import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/core/utils/exceptions.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ATUALIZAÇÃO 1: MÉTODO PARA ENVIAR E-MAIL DE VERIFICAÇÃO
  Future<void> registerUser(AppUser userData, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: userData.email,
        password: password,
      );

      if (userCredential.user != null) {
        // Envia o e-mail de verificação para o novo usuário
        await userCredential.user!.sendEmailVerification();

        AppUser userToSave = AppUser(
          uid: userCredential.user!.uid,
          email: userData.email,
          nome: userData.nome,
          userType: userData.userType,
          crm: userData.crm,
          cpf: userData.cpf,
        );
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
      throw AuthException('Ocorreu um erro inesperado durante o registro.');
    }
  }

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

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Erro ao fazer logout.');
    }
  }

  // ATUALIZAÇÃO 2: MÉTODO PARA RECUPERAÇÃO DE SENHA
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // Você pode adicionar um tratamento de erro mais específico aqui se quiser
      throw AuthException('Erro ao enviar e-mail de redefinição: ${e.message}');
    }
  }
}