import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';

final userServiceProvider = Provider((ref) => UserService());

final usersStreamProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(userServiceProvider).getUsersStream();
});

final patientsStreamProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(userServiceProvider).getPatientsStream();
});

final doctorStreamProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(userServiceProvider).getDoctorStream();
});

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
