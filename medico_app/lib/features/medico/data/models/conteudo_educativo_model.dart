import 'package:cloud_firestore/cloud_firestore.dart';

// Enum para os tipos de conteúdo, facilitando a filtragem e a exibição.
enum ConteudoTipo { artigo, video, pdf }

class ConteudoEducativo {
  final String id;
  final String titulo;
  final String descricao;
  final ConteudoTipo tipo;
  final String url;
  final String? thumbnailUrl; // URL para a imagem de capa (miniatura). Opcional.
  final DateTime dataPublicacao;
  final int ordem; // Campo para controlar a ordem de exibição (drag-and-drop).

  ConteudoEducativo({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.tipo,
    required this.url,
    this.thumbnailUrl,
    required this.dataPublicacao,
    required this.ordem,
  });

  // Construtor de fábrica para criar uma instância a partir de um documento do Firestore.
  factory ConteudoEducativo.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ConteudoEducativo(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      descricao: data['descricao'] ?? '',
      // Converte a string do banco de dados de volta para o enum.
      tipo: ConteudoTipo.values.firstWhere(
        (e) => e.toString() == 'ConteudoTipo.${data['tipo']}',
        orElse: () => ConteudoTipo.artigo,
      ),
      url: data['url'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      dataPublicacao: (data['dataPublicacao'] as Timestamp).toDate(),
      ordem: data['ordem'] ?? 0,
    );
  }
}

