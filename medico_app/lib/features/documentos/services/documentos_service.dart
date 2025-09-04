// medico_app/lib/features/documentos/services/documentos_service.dart

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

  Stream<List<Documento>> getDocumentosStream(String pacienteId) {
    return _firestore
        .collection('documentos')
        .where('destinatarioId', isEqualTo: pacienteId)
        .orderBy('dataUpload', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Documento.fromDocumentSnapshot(doc)).toList());
  }

  Future<void> uploadDocumento({
    required String remetenteId,
    required String destinatarioId,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: kIsWeb, // Pega os bytes apenas se for web
      );

      if (result != null) {
        final file = result.files.single;
        final fileName = file.name;
        Uint8List fileBytes;

        // CORREÇÃO: Pega os bytes do caminho no mobile, ou diretamente na web
        if (kIsWeb) {
          fileBytes = file.bytes!;
        } else {
          fileBytes = await File(file.path!).readAsBytes();
        }
        
        String fileType;
        final extension = fileName.split('.').last.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
          fileType = 'imagem';
        } else if (extension == 'pdf') {
          fileType = 'pdf';
        } else {
          fileType = 'outro';
        }

        final path = 'documentos/$destinatarioId/$fileName';
        final ref = _storage.ref(path);
        
        final mimeType = lookupMimeType(fileName);
        final metadata = SettableMetadata(contentType: mimeType);
        
        final uploadTask = ref.putData(fileBytes, metadata);
        final snapshot = await uploadTask.whenComplete(() => {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

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
      debugPrint("Erro inesperado: $e");
      throw Exception('Ocorreu um erro ao selecionar ou enviar o arquivo.');
    }
  }
}