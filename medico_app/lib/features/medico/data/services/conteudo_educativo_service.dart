// lib/features/medico/data/services/conteudo_educativo_service.dart

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:medico_app/features/medico/data/models/conteudo_educativo_model.dart';

class ConteudoEducativoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Usa o nome correto da coleção consistentemente
  final CollectionReference _conteudosCollection =
      FirebaseFirestore.instance.collection('conteudos_educativos');

  Stream<List<ConteudoEducativo>> getConteudos() {
    return _conteudosCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ConteudoEducativo.fromFirestore(doc);
      }).toList();
    });
  }

  Future<void> addConteudo({
    required String titulo,
    required String descricao,
    required List<String> tags,
    required String url,
    String? thumbnailUrl,
    required String medicoId,
  }) async {
    await _conteudosCollection.add({
      'titulo': titulo,
      'descricao': descricao,
      'tags': tags,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'medicoId': medicoId,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> updateConteudo({
    required String id,
    required String titulo,
    required String descricao,
    required List<String> tags,
    required String url,
    String? thumbnailUrl,
  }) async {
    await _conteudosCollection.doc(id).update({
      'titulo': titulo,
      'descricao': descricao,
      'tags': tags,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteConteudo(String id) async {
    await _conteudosCollection.doc(id).delete();
  }

  Future<String> uploadFile({
    required Uint8List fileBytes,
    required String fileName,
    required String medicoId,
  }) async {
    try {
      // ### CORREÇÃO APLICADA AQUI ###
      // O caminho agora corresponde exatamente à regra do Storage.
      final ref = _storage.ref(
          'conteudos_educativos/$medicoId/${DateTime.now().millisecondsSinceEpoch}_$fileName');
          
      final uploadTask = ref.putData(fileBytes);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Erro no upload do arquivo para o Storage: $e");
      // Relança o erro para que a UI possa tratá-lo.
      rethrow;
    }
  }
}