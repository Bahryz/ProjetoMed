import 'package:cloud_firestore/cloud_firestore.dart';

class ConteudoEducativo {
  final String id;
  final String titulo;
  final String descricao;
  final List<String> tags;
  final String url; // URL externa ou URL de download do Firebase Storage
  final String? thumbnailUrl; // Essencial para a nova UI
  final DateTime dataPublicacao;
  final String criadoPor; // ID do médico que criou

  ConteudoEducativo({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.tags,
    required this.url,
    this.thumbnailUrl,
    required this.dataPublicacao,
    required this.criadoPor,
  });

  factory ConteudoEducativo.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ConteudoEducativo(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      descricao: data['descricao'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      url: data['url'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      dataPublicacao: (data['dataPublicacao'] as Timestamp).toDate(),
      criadoPor: data['criadoPor'] ?? '',
    );
  }
}

