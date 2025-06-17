// lib/features/chat/services/user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Busca uma lista de todos os médicos
  Stream<List<AppUser>> getMedicosStream() {
    return _firestore.collection('medicos').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList();
    });
  }

  // Busca os dados de um usuário específico, seja ele médico ou paciente
  Future<AppUser?> getUserData(String uid) async {
    // Procura na coleção de médicos
    var doc = await _firestore.collection('medicos').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.data()!);
    }

    // Se não encontrar, procura na coleção de pacientes
    doc = await _firestore.collection('pacientes').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.data()!);
    }

    return null;
  }
}