// lib/features/medico/presentation/screens/conteudo_educativo_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medico_app/features/medico/data/models/conteudo_educativo_model.dart';
import 'package:medico_app/features/medico/data/services/conteudo_educativo_service.dart';

// O formulário foi movido para um widget separado que será mostrado em um modal
import 'package:medico_app/features/medico/presentation/widgets/add_edit_conteudo_form.dart';

class ConteudoEducativoScreen extends StatefulWidget {
  const ConteudoEducativoScreen({super.key});

  @override
  State<ConteudoEducativoScreen> createState() =>
      _ConteudoEducativoScreenState();
}

class _ConteudoEducativoScreenState extends State<ConteudoEducativoScreen> {
  final ConteudoEducativoService _service = ConteudoEducativoService();

  void _showAddEditSheet({ConteudoEducativo? conteudo}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: AddEditConteudoForm(
                conteudoParaEditar: conteudo,
                scrollController: scrollController,
              ),
            );
          },
        );
      },
    );
  }

  void _deleteConteudo(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza de que deseja excluir este conteúdo? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _service.deleteConteudo(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conteúdo excluído com sucesso.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Conteúdos'),
      ),
      body: StreamBuilder<List<ConteudoEducativo>>(
        stream: _service.getConteudos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum conteúdo adicionado.\nClique no botão + para começar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          final conteudos = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: conteudos.length,
            itemBuilder: (context, index) {
              return _buildConteudoCard(conteudos[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Novo Conteúdo'),
      ),
    );
  }

  Widget _buildConteudoCard(ConteudoEducativo conteudo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (conteudo.thumbnailUrl != null)
            CachedNetworkImage(
              imageUrl: conteudo.thumbnailUrl!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(height: 160, color: Colors.grey.shade300),
              errorWidget: (context, url, error) => Container(
                height: 160,
                color: Colors.grey.shade200,
                child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
              ),
            ),
          ListTile(
            title: Text(conteudo.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              conteudo.descricao,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 8), Text('Editar')]),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [Icon(Icons.delete_outline, size: 20), SizedBox(width: 8), Text('Excluir')]),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showAddEditSheet(conteudo: conteudo);
                } else if (value == 'delete') {
                  _deleteConteudo(conteudo.id);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: conteudo.tags.map((tag) => Chip(label: Text(tag))).toList(),
            ),
          ),
        ],
      ),
    );
  }
}