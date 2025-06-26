import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'users';

  // Retorna os dados de um usuário específico pelo UID
  Future<AppUser?> getUserData(String uid) async {
    try {
      final docSnapshot = await _firestore.collection(_collectionPath).doc(uid).get();
      if (docSnapshot.exists) {
        return AppUser.fromMap(docSnapshot.data()!);
      }
    } catch (e) {
      debugPrint("Erro ao buscar dados do usuário: $e");
    }
    return null;
  }

  // Retorna uma lista de todos os usuários, exceto o usuário logado
  Future<List<AppUser>> getTodosUsuarios({String? excluirId}) async {
    try {
      final querySnapshot = await _firestore.collection(_collectionPath).get();
      final users = querySnapshot.docs
          .map((doc) => AppUser.fromMap(doc.data()))
          .where((user) => user.uid != excluirId)
          .toList();
      return users;
    } catch (e) {
      debugPrint("Erro ao buscar todos os usuários: $e");
      return [];
    }
  }

  // Retorna um stream de médicos
  Stream<List<AppUser>> getMedicosStream() {
    return _firestore
        .collection(_collectionPath)
        .where('tipoUsuario', isEqualTo: 'medico')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList();
    });
  }

  // NOVO: Retorna um stream de todos os pacientes
  Stream<List<AppUser>> getPacientesStream() {
    return _firestore
        .collection(_collectionPath)
        .where('tipoUsuario', isEqualTo: 'paciente')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList();
    });
  }
}
