import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;

  const ImageViewerScreen({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Adiciona um botão de download (opcional, mas profissional)
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // Aqui você pode adicionar a lógica para salvar a imagem na galeria
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidade de download a ser implementada.')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4,
          // ATUALIZAÇÃO: Usando CachedNetworkImage para performance e caching
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain, // Garante que a imagem inteira seja visível
            // Widget a ser exibido enquanto a imagem está carregando
            placeholder: (context, url) => Center(
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            // Widget a ser exibido se ocorrer um erro ao carregar a imagem
            errorWidget: (context, url, error) => const Center(
              child: Icon(
                Icons.image_not_supported_outlined, // Ícone mais apropriado
                color: Colors.white,
                size: 50.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
