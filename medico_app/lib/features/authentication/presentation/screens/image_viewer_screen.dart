import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gallery_saver/gallery_saver.dart'; // <<< CORREÇÃO AQUI
import 'package:url_launcher/url_launcher.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;

  const ImageViewerScreen({super.key, required this.imageUrl});

  Future<void> _saveImage(BuildContext context) async {
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
        final uri = Uri.tryParse(imageUrl);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Não foi possível abrir a URL da imagem.');
        }
      } else {
        // Em mobile (Android/iOS), guarda diretamente na galeria
        await GallerySaver.saveImage(imageUrl); // <<< CORREÇÃO AQUI
        showSnackBar('Imagem guardada na galeria com sucesso!');
      }
    } catch (e) {
      debugPrint("Erro ao guardar imagem: $e");
      showSnackBar('Erro ao guardar a imagem.', isError: true);
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
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _saveImage(context),
            tooltip: 'Guardar imagem',
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
