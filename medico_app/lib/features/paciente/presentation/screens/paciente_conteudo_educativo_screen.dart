import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:medico_app/features/medico/data/models/conteudo_educativo_model.dart';
import 'package:medico_app/features/medico/data/services/conteudo_educativo_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PacienteConteudoEducativoScreen extends StatefulWidget {
  const PacienteConteudoEducativoScreen({super.key});

  @override
  State<PacienteConteudoEducativoScreen> createState() =>
      _PacienteConteudoEducativoScreenState();
}

class _PacienteConteudoEducativoScreenState
    extends State<PacienteConteudoEducativoScreen> {
  final ConteudoEducativoService _service = ConteudoEducativoService();
  final TextEditingController _searchController = TextEditingController();
  
  String _filtroTag = 'Todos';
  List<String> _todasAsTags = ['Todos'];
  String _searchQuery = '';
  // TODO: Implementar lógica de favoritos
  final List<String> _favoritos = []; 

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFavorito(String id) {
    setState(() {
      if (_favoritos.contains(id)) {
        _favoritos.remove(id);
      } else {
        _favoritos.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca de Saúde'),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
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
                  return const Center(child: Text('Nenhum conteúdo disponível.'));
                }

                final todosConteudos = snapshot.data!;
                _todasAsTags = ['Todos', 'Favoritos', ...todosConteudos.expand((c) => c.tags).toSet()];

                final conteudosFiltrados = todosConteudos.where((c) {
                  final correspondeTag = _filtroTag == 'Todos'
                      ? true
                      : _filtroTag == 'Favoritos'
                          ? _favoritos.contains(c.id)
                          : c.tags.contains(_filtroTag);

                  final correspondeBusca = _searchQuery.isEmpty ||
                      c.titulo.toLowerCase().contains(_searchQuery) ||
                      c.descricao.toLowerCase().contains(_searchQuery) ||
                      c.tags.any((t) => t.toLowerCase().contains(_searchQuery));
                      
                  return correspondeTag && correspondeBusca;
                }).toList();

                if (conteudosFiltrados.isEmpty) {
                  return const Center(child: Text('Nenhum resultado encontrado.'));
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por título, tema...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _todasAsTags.length,
        itemBuilder: (context, index) {
          final tag = _todasAsTags[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(tag),
              selected: _filtroTag == tag,
              onSelected: (_) => setState(() => _filtroTag = tag),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConteudoCard(ConteudoEducativo conteudo) {
    final isFavorito = _favoritos.contains(conteudo.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () async {
          final uri = Uri.tryParse(conteudo.url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (conteudo.thumbnailUrl != null)
                  CachedNetworkImage(
                    imageUrl: conteudo.thumbnailUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(height: 180, color: Colors.grey.shade300),
                    errorWidget: (context, url, error) => Container(height: 180, color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
                  )
                else
                  Container(height: 180, color: Theme.of(context).primaryColor.withOpacity(0.1), child: const Center(child: Icon(Icons.school, size: 50))),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(isFavorito ? Icons.bookmark : Icons.bookmark_border),
                    onPressed: () => _toggleFavorito(conteudo.id),
                    color: Colors.white,
                    style: IconButton.styleFrom(backgroundColor: Colors.black.withOpacity(0.4)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(conteudo.titulo, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    conteudo.descricao,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    children: conteudo.tags.map((tag) => Chip(label: Text(tag))).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
