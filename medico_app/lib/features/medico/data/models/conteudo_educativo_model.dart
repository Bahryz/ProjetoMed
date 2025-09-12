import 'package:cloud_firestore/cloud_firestore.dart';

class ConteudoEducativo {
  final String id;
  final String titulo;
  final String descricao;
  final List<String> tags;
  final String url;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final String medicoId;

  ConteudoEducativo({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.tags,
    required this.url,
    this.thumbnailUrl,
    required this.createdAt,
    required this.medicoId,
  });

  factory ConteudoEducativo.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ConteudoEducativo(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      descricao: data['descricao'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      url: data['url'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      // CORRIGIDO: Lendo 'createdAt'
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      // CORRIGIDO: Lendo 'medicoId'
      medicoId: data['medicoId'] ?? '',
    );
  }
}