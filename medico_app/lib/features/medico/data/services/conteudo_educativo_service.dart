import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:medico_app/features/medico/data/models/conteudo_educativo_model.dart';
import 'package:uuid/uuid.dart';

class ConteudoEducativoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Busca todos os conteúdos educativos, ordenados por data de publicação.
  Stream<List<ConteudoEducativo>> getConteudos() {
    return _firestore
        .collection('conteudos_educativos')
        .orderBy('dataPublicacao', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ConteudoEducativo.fromFirestore(doc))
          .toList();
    });
  }

  /// Faz o upload de um arquivo para o Firebase Storage.
  /// Retorna a URL de download do arquivo.
  Future<String> uploadFile({
    required Uint8List fileBytes,
    required String fileName,
    required String medicoId,
  }) async {
    try {
      final fileId = _uuid.v4();
      final ref = _storage.ref('conteudos_educativos/$medicoId/$fileId-$fileName');
      final uploadTask = ref.putData(fileBytes);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Erro no upload do arquivo: $e');
      rethrow;
    }
  }

  /// Adiciona um novo documento de conteúdo na coleção do Firestore.
  Future<void> addConteudo({
    required String titulo,
    required String descricao,
    required List<String> tags,
    required String url,
    required String medicoId,
    String? thumbnailUrl,
  }) async {
    await _firestore.collection('conteudos_educativos').add({
      'titulo': titulo,
      'descricao': descricao,
      'tags': tags,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'criadoPor': medicoId,
      'dataPublicacao': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteConteudo(String conteudoId) async {
    await _firestore.collection('conteudos_educativos').doc(conteudoId).delete();
  }
}

