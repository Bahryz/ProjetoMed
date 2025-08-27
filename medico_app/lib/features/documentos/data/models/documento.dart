import 'package:cloud_firestore/cloud_firestore.dart';

class Documento {
  final String id;
  final String remetenteId;
  final String destinatarioId;
  final String nomeArquivo;
  final String url;
  final String tipo; // 'imagem', 'pdf', 'outro'
  final DateTime dataUpload;

  Documento({
    required this.id,
    required this.remetenteId,
    required this.destinatarioId,
    required this.nomeArquivo,
    required this.url,
    required this.tipo,
    required this.dataUpload,
  });

  Map<String, dynamic> toJson() {
    return {
      'remetenteId': remetenteId,
      'destinatarioId': destinatarioId,
      'nomeArquivo': nomeArquivo,
      'url': url,
      'tipo': tipo,
      'dataUpload': dataUpload,
    };
  }

  factory Documento.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Documento(
      id: doc.id,
      remetenteId: data['remetenteId'] ?? '',
      destinatarioId: data['destinatarioId'] ?? '',
      nomeArquivo: data['nomeArquivo'] ?? 'Arquivo sem nome',
      url: data['url'] ?? '',
      tipo: data['tipo'] ?? 'outro',
      dataUpload: (data['dataUpload'] as Timestamp).toDate(),
    );
  }
}