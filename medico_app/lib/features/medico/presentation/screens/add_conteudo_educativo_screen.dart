import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medico_app/features/medico/data/models/conteudo_educativo_model.dart';
import 'package:medico_app/features/medico/data/services/conteudo_educativo_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AddConteudoEducativoScreen extends StatefulWidget {
  const AddConteudoEducativoScreen({super.key});

  @override
  State<AddConteudoEducativoScreen> createState() =>
      _AddConteudoEducativoScreenState();
}

class _AddConteudoEducativoScreenState extends State<AddConteudoEducativoScreen> {
  final ConteudoEducativoService _service = ConteudoEducativoService();
  ConteudoTipo? _filtroSelecionado;
  List<ConteudoEducativo> _conteudos = [];

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
                  return _buildEmptyState();
                }

                _conteudos = snapshot.data!;
                final conteudosFiltrados = _conteudos.where((c) {
                  return _filtroSelecionado == null ||
                      c.tipo == _filtroSelecionado;
                }).toList();

                if (conteudosFiltrados.isEmpty) {
                  return Center(
                      child: Text(
                          'Nenhum conteúdo do tipo "${_filtroSelecionado?.name.toUpperCase()}" encontrado.'));
                }

                return ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: conteudosFiltrados.length,
                  itemBuilder: (context, index) {
                    return _buildConteudoCard(conteudosFiltrados[index], index);
                  },
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (_filtroSelecionado != null) {
                        final item = conteudosFiltrados.removeAt(oldIndex);
                        conteudosFiltrados.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
                        _conteudos = snapshot.data!; 
                        for (var filteredItem in conteudosFiltrados.reversed) {
                          _conteudos.removeWhere((item) => item.id == filteredItem.id);
                          _conteudos.insert(0, filteredItem);
                        }

                      } else {
                         if (newIndex > oldIndex) {
                           newIndex -= 1;
                         }
                         final item = _conteudos.removeAt(oldIndex);
                         _conteudos.insert(newIndex, item);
                      }
                      _service.updateOrdem(_conteudos);
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Ainda não há conteúdo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text('Adicione o seu primeiro material educativo.', style: TextStyle(fontSize: 16, color: Colors.grey[400])),
          const SizedBox(height: 24),
           ElevatedButton.icon(
            onPressed: () => context.push('/add-conteudo-educativo'),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Conteúdo'),
          )
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
      ),
    );
  }

  Widget _buildConteudoCard(ConteudoEducativo conteudo, int index) {
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
      key: ValueKey(conteudo.id),
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
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Miniatura
              SizedBox(
                width: 100,
                height: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: conteudo.thumbnailUrl ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey.shade800),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade800,
                      child: Icon(icon, color: color, size: 40),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Informações do Conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(conteudo.titulo,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      conteudo.descricao,
                      style: TextStyle(color: Colors.grey[400]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(
                          avatar: Icon(icon, size: 16),
                          label: Text(conteudo.tipo.name.toUpperCase()),
                          visualDensity: VisualDensity.compact,
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('dd/MM/yy').format(conteudo.dataPublicacao),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Alça para Reordenar
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(left: 12.0),
                  child: Icon(Icons.drag_handle_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

