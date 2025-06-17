// lib/features/chat/services/chat_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart'; // Ajuste o import se necessário

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Obter stream de conversas de um usuário
  Stream<QuerySnapshot> getConversasStream(String userId) {
    return _firestore
        .collection('conversas')
        .where('participantes', arrayContains: userId)
        .orderBy('timestampUltimaMensagem', descending: true)
        .snapshots();
  }

  // Obter stream de mensagens de uma conversa específica
  Stream<QuerySnapshot> getMensagensStream(String conversaId) {
    return _firestore
        .collection('conversas')
        .doc(conversaId)
        .collection('mensagens')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Enviar uma mensagem de texto
  Future<void> enviarMensagem(String conversaId, String remetenteId, String texto) async {
    if (texto.trim().isEmpty) return;

    final messagesRef = _firestore.collection('conversas').doc(conversaId).collection('mensagens');
    final conversationRef = _firestore.collection('conversas').doc(conversaId);

    await messagesRef.add({
      'remetenteId': remetenteId,
      'tipo': 'texto',
      'conteudo': texto,
      'timestamp': FieldValue.serverTimestamp(),
      'statusLeitura': 'enviado',
    });

    // Atualizar a última mensagem na conversa para facilitar a listagem
    await conversationRef.update({
      'ultimaMensagem': texto,
      'timestampUltimaMensagem': FieldValue.serverTimestamp(),
    });
  }

  // Enviar um arquivo (imagem, áudio, etc.)
  Future<void> enviarArquivo(String conversaId, String remetenteId, File arquivo, String tipo) async {
    // 1. Criar caminho no Firebase Storage
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${arquivo.path.split('/').last}';
    final path = 'chat_media/$conversaId/$fileName';
    final ref = _storage.ref(path);

    // 2. Fazer upload do arquivo
    final uploadTask = ref.putFile(arquivo);
    final snapshot = await uploadTask.whenComplete(() => {});
    final downloadUrl = await snapshot.ref.getDownloadURL();

    // 3. Salvar a mensagem no Firestore com a URL do arquivo
    final messagesRef = _firestore.collection('conversas').doc(conversaId).collection('mensagens');
    await messagesRef.add({
      'remetenteId': remetenteId,
      'tipo': tipo, // "imagem", "audio", "arquivo"
      'conteudo': downloadUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'statusLeitura': 'enviado',
    });
    
    // 4. Atualizar última mensagem
     await _firestore.collection('conversas').doc(conversaId).update({
      'ultimaMensagem': tipo == 'imagem' ? '📷 Foto' : (tipo == 'audio' ? '🎤 Áudio' : '📄 Arquivo'),
      'timestampUltimaMensagem': FieldValue.serverTimestamp(),
    });
  }

  // Marcar mensagens como lidas
  Future<void> marcarComoLida(String conversaId, String mensagemId) async {
    await _firestore
        .collection('conversas')
        .doc(conversaId)
        .collection('mensagens')
        .doc(mensagemId)
        .update({'statusLeitura': 'lido'});
  }
}