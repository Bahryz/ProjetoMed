import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medico_app/features/documentos/data/models/documento.dart';

class DocumentosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Futuramente, adicione métodos para upload, deleção, etc.
}