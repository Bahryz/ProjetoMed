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
  ConteudoTipo? _filtroSelecionado;

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
                      child: Text('Nenhum conteúdo educativo adicionado.'));
                }

                final todosConteudos = snapshot.data!;
                final conteudosFiltrados = todosConteudos.where((c) {
                  return _filtroSelecionado == null ||
                      c.tipo == _filtroSelecionado;
                }).toList();

                if (conteudosFiltrados.isEmpty) {
                  return Center(child: Text('Nenhum conteúdo do tipo "${_filtroSelecionado?.name.toUpperCase()}" encontrado.'));
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      alignment: Alignment.center,
      child: Wrap(
        spacing: 8.0,
        children: [
          FilterChip(
            label: const Text('Todos'),
            selected: _filtroSelecionado == null,
            onSelected: (selected) {
              setState(() => _filtroSelecionado = null);
            },
          ),
          ...ConteudoTipo.values.map((tipo) {
            return FilterChip(
              label: Text(tipo.name.toUpperCase()),
              selected: _filtroSelecionado == tipo,
              onSelected: (selected) {
                setState(() {
                  _filtroSelecionado = selected ? tipo : null;
                });
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConteudoCard(ConteudoEducativo conteudo) {
    IconData icon;
    Color color;

    switch (conteudo.tipo) {
      case ConteudoTipo.video:
        icon = Icons.videocam_rounded;
        color = Colors.redAccent;
        break;
      case ConteudoTipo.pdf:
        icon = Icons.picture_as_pdf_rounded;
        color = Colors.blueAccent;
        break;
      default:
        icon = Icons.article_rounded;
        color = Colors.orangeAccent;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
            final uri = Uri.tryParse(conteudo.url);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Não foi possível abrir o link.')),
              );
            }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(conteudo.titulo,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(conteudo.descricao,
                        style: TextStyle(color: Colors.grey[400]), maxLines: 2, overflow: TextOverflow.ellipsis,),
                    const SizedBox(height: 8),
                    Text(
                      'Publicado em: ${DateFormat('dd/MM/yyyy').format(conteudo.dataPublicacao)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                   final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirmar Exclusão'),
                          content: const Text('Tem certeza que deseja excluir este conteúdo?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Excluir')),
                          ],
                        ),
                      ) ?? false;

                    if (confirm) {
                      await _service.deleteConteudo(conteudo);
                    }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}