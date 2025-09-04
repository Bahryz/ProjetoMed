import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:medico_app/features/documentos/data/models/documento.dart';

class DocumentosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Stream para buscar todos os documentos de um paciente
  Stream<List<Documento>> getDocumentosStream(String pacienteId) {
    return _firestore
        .collection('documentos')
        .where('destinatarioId', isEqualTo: pacienteId)
        .orderBy('dataUpload', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Documento.fromDocumentSnapshot(doc)).toList());
  }

  // Novo método para upload de documentos
  Future<void> uploadDocumento({
    required String remetenteId,
    required String destinatarioId,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Permitir qualquer tipo de arquivo
      );

      if (result != null && result.files.single.bytes != null) {
        final fileBytes = result.files.single.bytes!;
        final fileName = result.files.single.name;
        
        // 1. Lógica para determinar o tipo do arquivo
        String fileType;
        final extension = fileName.split('.').last.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
          fileType = 'imagem';
        } else if (extension == 'pdf') {
          fileType = 'pdf';
        } else {
          fileType = 'outro';
        }

        // 2. Upload para o Firebase Storage
        final path = 'documentos/$destinatarioId/$fileName';
        final ref = _storage.ref(path);
        
        final mimeType = lookupMimeType(fileName);
        final metadata = SettableMetadata(contentType: mimeType);
        
        final uploadTask = ref.putData(fileBytes, metadata);
        final snapshot = await uploadTask.whenComplete(() => {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // 3. Salvar referência no Firestore
        await _firestore.collection('documentos').add({
          'remetenteId': remetenteId,
          'destinatarioId': destinatarioId,
          'nomeArquivo': fileName,
          'url': downloadUrl,
          'tipo': fileType,
          'dataUpload': FieldValue.serverTimestamp(),
        });

      }
    } on FirebaseException catch (e) {
      debugPrint("Erro no upload do arquivo: ${e.code} - ${e.message}");
      throw Exception('Falha ao enviar o arquivo.');
    } catch (e) {
      throw Exception('Ocorreu um erro ao selecionar ou enviar o arquivo.');
    }
  }
}