import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medico_app/features/medico/data/models/conteudo_educativo_model.dart';
import 'package:medico_app/features/medico/data/services/conteudo_educativo_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ConteudoEducativoScreen extends StatefulWidget {
  const ConteudoEducativoScreen({super.key});

  @override
  State<ConteudoEducativoScreen> createState() =>
      _ConteudoEducativoScreenState();
}

class _ConteudoEducativoScreenState extends State<ConteudoEducativoScreen> {
  final ConteudoEducativoService _service = ConteudoEducativoService();
  String? _filtroSelecionado;
  List<String> _todasAsTags = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conteúdo Educativo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/add-conteudo-educativo'),
            tooltip: 'Adicionar Novo Conteúdo',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<List<ConteudoEducativo>>(
              stream: _service.getConteudos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Nenhum conteúdo educativo adicionado.'),
                  );
                }

                final todosConteudos = snapshot.data!;
                _todasAsTags =
                    todosConteudos.expand((c) => c.tags).toSet().toList();

                final conteudosFiltrados = todosConteudos.where((c) {
                  return _filtroSelecionado == null ||
                      c.tags.contains(_filtroSelecionado);
                }).toList();

                if (conteudosFiltrados.isEmpty) {
                  return Center(
                      child: Text(
                          'Nenhum conteúdo com a tag "$_filtroSelecionado" foi encontrado.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: conteudosFiltrados.length,
                  itemBuilder: (context, index) {
                    return _buildConteudoCard(conteudosFiltrados[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8.0,
        children: [
          FilterChip(
            label: const Text('Todos'),
            selected: _filtroSelecionado == null,
            onSelected: (_) => setState(() => _filtroSelecionado = null),
          ),
          ..._todasAsTags.map((tag) {
            return FilterChip(
              label: Text(tag),
              selected: _filtroSelecionado == tag,
              onSelected: (selected) {
                setState(() => _filtroSelecionado = selected ? tag : null);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConteudoCard(ConteudoEducativo conteudo) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final uri = Uri.tryParse(conteudo.url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Não foi possível abrir o link.')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      conteudo.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _deleteConteudo(conteudo.id),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                conteudo.descricao,
                style: TextStyle(color: Colors.grey.shade600),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: conteudo.tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          labelStyle: const TextStyle(fontSize: 12),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Publicado em: ${DateFormat('dd/MM/yyyy').format(conteudo.dataPublicacao)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteConteudo(String conteudoId) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content:
                const Text('Tem certeza que deseja excluir este conteúdo?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar')),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Excluir')),
            ],
          ),
        ) ??
        false;

    if (confirm && mounted) {
      try {
        await _service.deleteConteudo(conteudoId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conteúdo excluído com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e')),
        );
      }
    }
  }
}