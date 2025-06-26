import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<AppUser>> getPendingMedicos() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'medico')
          .where('status', isEqualTo: 'pendente')
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return AppUser(
          uid: data['uid'] ?? doc.id,
          nome: data['nome'] ?? '',
          email: data['email'],
          crm: data['crm'],
          telefone: data['telefone'],
          userType: data['userType'] ?? 'medico',
          cpf: data['cpf'],
          status: data['status'],
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> updateUserStatus(String uid, String status) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'status': status,
      });
    } catch (e) {
      throw Exception("Não foi possível atualizar o status do usuário.");
    }
  }
}
