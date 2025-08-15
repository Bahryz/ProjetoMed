import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> getOrCreateConversation(
      String currentUserId, String otherUserId) async {
    List<String> userIds = [currentUserId, otherUserId];
    userIds.sort();
    String conversaId = userIds.join('_');

    final conversationRef = _firestore.collection('conversas').doc(conversaId);
    final docSnapshot = await conversationRef.get();

    if (!docSnapshot.exists) {
      await conversationRef.set({
        'participantes': [currentUserId, otherUserId],
        'timestampUltimaMensagem': FieldValue.serverTimestamp(),
      });
    }

    return conversaId;
  }

  Stream<QuerySnapshot> getConversasStream(String userId) {
    return _firestore
        .collection('conversas')
        .where('participantes', arrayContains: userId)
        .orderBy('timestampUltimaMensagem', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getMensagensStream(String conversaId) {
    return _firestore
        .collection('conversas')
        .doc(conversaId)
        .collection('mensagens')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> enviarMensagem(
      String conversaId, String remetenteId, String texto) async {
    if (texto.trim().isEmpty) return;

    final messagesRef =
        _firestore.collection('conversas').doc(conversaId).collection('mensagens');
    final conversationRef = _firestore.collection('conversas').doc(conversaId);

    await messagesRef.add({
      'remetenteId': remetenteId,
      'tipo': 'texto',
      'conteudo': texto,
      'timestamp': FieldValue.serverTimestamp(),
      'statusLeitura': 'enviado',
    });

    await conversationRef.update({
      'ultimaMensagem': texto,
      'timestampUltimaMensagem': FieldValue.serverTimestamp(),
    });
  }

  Future<void> enviarArquivo(
    String conversaId,
    String remetenteId,
    Uint8List fileBytes,
    String nomeArquivo,
    String tipo,
  ) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$nomeArquivo';
      final path = 'chat_media/$conversaId/$fileName';
      final ref = _storage.ref(path);

      final mimeType = lookupMimeType(nomeArquivo);
      final metadata = SettableMetadata(contentType: mimeType);

      final uploadTask = ref.putData(fileBytes, metadata);

      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('URL de Download Gerada com MIME Type ($mimeType): $downloadUrl');

      final messagesRef = _firestore
          .collection('conversas')
          .doc(conversaId)
          .collection('mensagens');
      await messagesRef.add({
        'remetenteId': remetenteId,
        'tipo': tipo,
        'conteudo': downloadUrl,
        'nomeArquivo': nomeArquivo,
        'timestamp': FieldValue.serverTimestamp(),
        'statusLeitura': 'enviado',
      });

      await _firestore.collection('conversas').doc(conversaId).update({
        'ultimaMensagem': tipo == 'imagem' ? '📷 Foto' : '📄 $nomeArquivo',
        'timestampUltimaMensagem': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint("Erro no upload do arquivo: ${e.code} - ${e.message}");
      throw Exception('Falha ao enviar o arquivo.');
    }
  }

  Future<void> marcarComoLida(String conversaId, String mensagemId) async {
    await _firestore
        .collection('conversas')
        .doc(conversaId)
        .collection('mensagens')
        .doc(mensagemId)
        .update({'statusLeitura': 'lido'});
  }
}