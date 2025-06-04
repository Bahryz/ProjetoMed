// IMPORTS ADICIONADOS PARA RESOLVER OS ERROS
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getter para o usuário atual (será usado no roteador)
  User? get currentUser => _auth.currentUser;

  // Stream para ouvir o estado da autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Método para registrar um novo usuário
  Future<void> registerUser(AppUser userData, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: userData.email,
        password: password,
      );

      if (userCredential.user != null) {
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData.toMap());
      }
    } on FirebaseAuthException catch (e) {
      // Recomendo usar exceções personalizadas aqui para melhor feedback na UI
      throw Exception('Erro ao registrar: ${e.message}');
    } catch (e) {
      throw Exception('Ocorreu um erro inesperado.');
    }
  }

  // Método para fazer login
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception('Erro ao fazer login: ${e.message}');
    } catch (e) {
      throw Exception('Ocorreu um erro inesperado.');
    }
  }

  // Método para fazer logout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Erro ao fazer logout.');
    }
  }
}