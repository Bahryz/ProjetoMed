import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:medico_app/features/medico/data/models/conteudo_educativo_model.dart';

class ConteudoEducativoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Retorna um stream com a lista de todos os conteúdos educativos, ordenados pela propriedade 'ordem'.
  Stream<List<ConteudoEducativo>> getConteudos() {
    return _firestore
        .collection('conteudo_educativo')
        .orderBy('ordem')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ConteudoEducativo.fromFirestore(doc))
          .toList();
    });
  }

  /// Adiciona um novo documento de conteúdo educativo no Firestore.
  Future<void> addConteudo({
    required String titulo,
    required String descricao,
    required ConteudoTipo tipo,
    required String url,
    String? thumbnailUrl,
  }) async {
    try {
      // Pega a contagem atual de documentos para definir a ordem do novo item.
      final count = await _firestore.collection('conteudo_educativo').count().get();
      await _firestore.collection('conteudo_educativo').add({
        'titulo': titulo,
        'descricao': descricao,
        'tipo': tipo.name,
        'url': url,
        'thumbnailUrl': thumbnailUrl,
        'dataPublicacao': FieldValue.serverTimestamp(),
        'ordem': count.count,
      });
    } catch (e) {
      debugPrint("Erro ao adicionar conteúdo: $e");
      throw Exception("Não foi possível adicionar o conteúdo.");
    }
  }

  /// Deleta um conteúdo (documento do Firestore e arquivos associados no Storage).
  Future<void> deleteConteudo(ConteudoEducativo conteudo) async {
    try {
      await _firestore.collection('conteudo_educativo').doc(conteudo.id).delete();
      // Deleta o arquivo principal.
      if (conteudo.url.isNotEmpty && conteudo.url.contains('firebasestorage.googleapis.com')) {
          await _storage.refFromURL(conteudo.url).delete();
      }
      // Deleta a miniatura, se existir.
      if (conteudo.thumbnailUrl != null && conteudo.thumbnailUrl!.isNotEmpty && conteudo.thumbnailUrl!.contains('firebasestorage.googleapis.com')) {
         await _storage.refFromURL(conteudo.thumbnailUrl!).delete();
      }
    } on FirebaseException catch (e) {
      // Ignora o erro "object-not-found" caso o ficheiro já tenha sido apagado manualmente
      if (e.code != 'object-not-found') {
        debugPrint("Erro ao deletar conteúdo: ${e.message}");
        throw Exception("Falha ao deletar o material.");
      }
    }
  }

  /// Atualiza a ordem dos conteúdos no Firestore usando uma transação em lote (batch).
  Future<void> updateOrdem(List<ConteudoEducativo> conteudos) async {
    final batch = _firestore.batch();
    for (int i = 0; i < conteudos.length; i++) {
      final docRef = _firestore.collection('conteudo_educativo').doc(conteudos[i].id);
      batch.update(docRef, {'ordem': i});
    }
    await batch.commit();
  }

  /// Faz o upload de um arquivo (bytes ou caminho do ficheiro) para o Firebase Storage.
  Future<String> uploadFile(PlatformFile file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = (kIsWeb && file.bytes != null)
          ? ref.putData(file.bytes!)
          : ref.putFile(File(file.path!));

      final snapshot = await uploadTask.whenComplete(() => {});
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint("Erro no upload do ficheiro: ${e.message}");
      throw Exception("Falha ao enviar o ficheiro.");
    }
  }
}

