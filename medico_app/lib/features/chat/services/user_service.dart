import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método adicionado para buscar um stream de médicos aprovados
  Stream<List<AppUser>> getMedicosStream() {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'medico') // Filtra para pegar apenas médicos
        .where('status', isEqualTo: 'aprovado') // Filtra para pegar apenas os aprovados
        .snapshots() // Retorna um Stream que atualiza em tempo real
        .map((snapshot) {
      try {
        // Mapeia cada documento do Firestore para um objeto AppUser
        return snapshot.docs
            .map((doc) => AppUser.fromDocumentSnapshot(doc))
            .toList();
      } catch (e) {
        print('Erro ao converter médicos: $e');
        return [];
      }
    });
  }
  
  // O método getUser continua aqui caso você precise dele em outro lugar.
  Future<AppUser?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromDocumentSnapshot(doc);
      }
    } catch (e) {
      print(e);
    }
    return null;
  }
}