import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';


class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<AppUser>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromDocumentSnapshot(doc))
          .where((user) => user.uid != _auth.currentUser?.uid)
          .toList();
    });
  }

  Stream<List<AppUser>> getPatientsStream() {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'paciente')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  Stream<AppUser?> getDoctorStream() {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'medico')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return AppUser.fromDocumentSnapshot(snapshot.docs.first);
      }
      return null;
    });
  }
}