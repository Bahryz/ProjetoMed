import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:medico_app/features/authentication/presentation/screens/image_viewer_screen.dart';
import 'package:medico_app/features/documentos/data/models/documento.dart';
import 'package:medico_app/features/documentos/services/documentos_service.dart';
import 'package:url_launcher/url_launcher.dart';

enum TipoDocumento { todos, imagem, pdf, outro }

class DocumentosScreen extends StatefulWidget {
  const DocumentosScreen({super.key});

  @override
  State<DocumentosScreen> createState() => _DocumentosScreenState();
}

class _DocumentosScreenState extends State<DocumentosScreen> {
  TipoDocumento _filtroTipo = TipoDocumento.todos;
  
  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final currentUser = authController.user;

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Documentos'),
        actions: [
          _buildFilterButton(),
        ],
      ),
      body: StreamBuilder<List<Documento>>(
        stream: DocumentosService().getDocumentosStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar documentos: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum documento encontrado.'));
          }

          final documentos = snapshot.data!.where((doc) {
            if (_filtroTipo == TipoDocumento.todos) return true;
            return doc.tipo == _filtroTipo.name;
          }).toList();

          if (documentos.isEmpty) {
            return const Center(child: Text('Nenhum documento encontrado com este filtro.'));
          }

          return ListView.builder(
            itemCount: documentos.length,
            itemBuilder: (context, index) {
              final doc = documentos[index];
              return _buildDocumentoTile(doc);
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterButton() {
    return PopupMenuButton<TipoDocumento>(
      icon: const Icon(Icons.filter_list),
      onSelected: (TipoDocumento result) {
        setState(() {
          _filtroTipo = result;
        });
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<TipoDocumento>>[
        const PopupMenuItem<TipoDocumento>(
          value: TipoDocumento.todos,
          child: Text('Todos'),
        ),
        const PopupMenuItem<TipoDocumento>(
          value: TipoDocumento.imagem,
          child: Text('Imagens'),
        ),
        const PopupMenuItem<TipoDocumento>(
          value: TipoDocumento.pdf,
          child: Text('PDFs'),
        ),
        const PopupMenuItem<TipoDocumento>(
          value: TipoDocumento.outro,
          child: Text('Outros Arquivos'),
        ),
      ],
    );
  }

  Widget _buildDocumentoTile(Documento doc) {
    final icon = doc.tipo == 'imagem' ? Icons.image : Icons.insert_drive_file;
    final date = DateFormat('dd/MM/yyyy').format(doc.dataUpload);

    return ListTile(
      leading: Icon(icon),
      title: Text(doc.nomeArquivo),
      subtitle: Text('Tipo: ${doc.tipo.toUpperCase()} - Data: $date'),
      onTap: () async {
        if (doc.tipo == 'imagem') {
          // Reutilize sua tela de visualização de imagem
          context.push('/image-viewer', extra: doc.url);
        } else {
          final uri = Uri.tryParse(doc.url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Não foi possível abrir o arquivo.')),
            );
          }
        }
      },
    );
  }
}