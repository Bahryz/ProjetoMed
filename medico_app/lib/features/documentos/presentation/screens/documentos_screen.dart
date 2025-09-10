import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
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
        elevation: 1,
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
            return _buildEmptyState();
          }

          final documentos = snapshot.data!.where((doc) {
            if (_filtroTipo == TipoDocumento.todos) return true;
            return doc.tipo == _filtroTipo.name;
          }).toList();

          if (documentos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Nenhum documento do tipo ${_filtroTipo.name.toUpperCase()} encontrado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documentos.length,
            itemBuilder: (context, index) {
              final doc = documentos[index];
              return _buildDocumentoCard(doc);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final currentUser = context.read<AuthController>().user;
          if (currentUser != null) {
            try {
              await DocumentosService().uploadDocumento(
                remetenteId: currentUser.uid,
                destinatarioId: currentUser.uid,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Documento enviado com sucesso!')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            }
          }
        },
        tooltip: 'Adicionar novo documento',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 80, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          const Text(
            'Nenhum documento aqui.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Todos os seus documentos salvos aparecerão aqui.',
            style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final currentUser = context.read<AuthController>().user;
              if (currentUser != null) {
                try {
                  await DocumentosService().uploadDocumento(
                    remetenteId: currentUser.uid,
                    destinatarioId: currentUser.uid,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Documento enviado com sucesso!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              }
            },
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Adicionar Documento'),
          )
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return PopupMenuButton<TipoDocumento>(
      icon: const Icon(Icons.filter_list_rounded),
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

  Widget _buildDocumentoCard(Documento doc) {
    IconData icon;
    Color color;

    switch (doc.tipo) {
      case 'imagem':
        icon = Icons.image_rounded;
        color = Colors.blueAccent;
        break;
      case 'pdf':
        icon = Icons.picture_as_pdf_rounded;
        color = Colors.redAccent;
        break;
      default:
        icon = Icons.insert_drive_file_rounded;
        color = Colors.grey;
        break;
    }

    final date = DateFormat('dd/MM/yyyy').format(doc.dataUpload);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 30, color: color),
        ),
        title: Text(
          doc.nomeArquivo,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Tipo: ${doc.tipo.toUpperCase()} - Data: $date',
          style: TextStyle(color: Colors.grey[400]),
        ),
        trailing: const Icon(Icons.download_rounded),
        onTap: () async {
          final uri = Uri.tryParse(doc.url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Não foi possível abrir o arquivo.')),
            );
          }
        },
      ),
    );
  }
}