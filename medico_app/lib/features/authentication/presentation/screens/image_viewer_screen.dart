import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:url_launcher/url_launcher.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;

  const ImageViewerScreen({super.key, required this.imageUrl});

  // Função para salvar a imagem
  Future<void> _saveImage(BuildContext context) async {
    // Exibe uma snackbar de feedback
    showSnackBar(String message, {bool isError = false}) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError ? Colors.red : Colors.green,
          ),
        );
      }
    }

    try {
      if (kIsWeb) {
        // Na web, abre a imagem em uma nova aba para o usuário salvar manualmente
        final uri = Uri.tryParse(imageUrl);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Não foi possível abrir a URL da imagem.');
        }
      } else {
        // Em mobile (Android/iOS), salva diretamente na galeria
        await GallerySaver.saveImage(imageUrl);
        showSnackBar('Imagem salva na galeria com sucesso!');
      }
    } catch (e) {
      debugPrint("Erro ao salvar imagem: $e");
      showSnackBar('Erro ao salvar a imagem.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Botão de Download
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _saveImage(context),
            tooltip: 'Salvar imagem',
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
            errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white, size: 50),
          ),
        ),
      ),
    );
  }
}
