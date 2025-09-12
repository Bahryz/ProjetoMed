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
  // TODO: Substituir por uma lógica de persistência (SharedPreferences ou Firestore)
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

  // Novo método para agrupar conteúdos por tag
  Map<String, List<ConteudoEducativo>> _agruparConteudosPorTag(List<ConteudoEducativo> conteudos) {
    final Map<String, List<ConteudoEducativo>> mapa = {};
    for (var conteudo in conteudos) {
      for (var tag in conteudo.tags) {
        if (mapa[tag] == null) {
          mapa[tag] = [];
        }
        mapa[tag]!.add(conteudo);
      }
    }
    return mapa;
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
                
                final conteudosVisiveis = todosConteudos.where((c) {
                  final correspondeBusca = _searchQuery.isEmpty ||
                      c.titulo.toLowerCase().contains(_searchQuery) ||
                      c.descricao.toLowerCase().contains(_searchQuery) ||
                      c.tags.any((t) => t.toLowerCase().contains(_searchQuery));
                  
                  if (_filtroTag == 'Todos') return correspondeBusca;
                  if (_filtroTag == 'Favoritos') return _favoritos.contains(c.id) && correspondeBusca;
                  return c.tags.contains(_filtroTag) && correspondeBusca;
                }).toList();
                
                if (conteudosVisiveis.isEmpty) {
                  return const Center(child: Text('Nenhum resultado encontrado.'));
                }
                
                // Se um filtro está ativo (exceto favoritos), mostra uma lista simples
                if (_filtroTag != 'Todos' && _filtroTag != 'Favoritos') {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: conteudosVisiveis.length,
                    itemBuilder: (context, index) {
                      return _buildConteudoCardVertical(conteudosVisiveis[index]);
                    },
                  );
                }

                final conteudosAgrupados = _agruparConteudosPorTag(conteudosVisiveis);
                
                return ListView(
                  children: [
                    // Exibe a seção de Favoritos primeiro se selecionada
                    if (_filtroTag == 'Favoritos' || (_filtroTag == 'Todos' && _favoritos.isNotEmpty))
                      _buildConteudoSection('Favoritos', conteudosVisiveis.where((c) => _favoritos.contains(c.id)).toList()),
                    
                    // Exibe as outras seções
                    ...conteudosAgrupados.entries.map((entry) {
                      return _buildConteudoSection(entry.key, entry.value);
                    }).toList(),
                  ],
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
          fillColor: Theme.of(context).scaffoldBackgroundColor.withAlpha(200),
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

  // Seção com scroll horizontal
  Widget _buildConteudoSection(String titulo, List<ConteudoEducativo> conteudos) {
    if (conteudos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            titulo,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: conteudos.length,
            itemBuilder: (context, index) {
              return _buildConteudoCardHorizontal(conteudos[index]);
            },
          ),
        ),
      ],
    );
  }

  // Card para listas horizontais (mais compacto)
  Widget _buildConteudoCardHorizontal(ConteudoEducativo conteudo) {
    final isFavorito = _favoritos.contains(conteudo.id);
    return SizedBox(
      width: 160,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(right: 12),
        child: InkWell(
          onTap: () => _abrirUrl(conteudo.url),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  CachedNetworkImage(
                    imageUrl: conteudo.thumbnailUrl ?? "URL_PADRAO",
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey.shade800),
                    errorWidget: (context, url, error) => Container(height: 120, color: Colors.grey.shade800, child: const Icon(Icons.school, color: Colors.white70)),
                  ),
                  _buildBotaoFavorito(isFavorito, () => _toggleFavorito(conteudo.id)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  conteudo.titulo,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text(
                  conteudo.tags.join(', '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card para a lista vertical (quando um filtro está ativo)
  Widget _buildConteudoCardVertical(ConteudoEducativo conteudo) {
    final isFavorito = _favoritos.contains(conteudo.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () => _abrirUrl(conteudo.url),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.topRight,
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
                
                _buildBotaoFavorito(isFavorito, () => _toggleFavorito(conteudo.id)),
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

  Widget _buildBotaoFavorito(bool isFavorito, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        backgroundColor: Colors.black.withOpacity(0.5),
        radius: 18,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            isFavorito ? Icons.bookmark : Icons.bookmark_border,
            color: Colors.white,
            size: 20,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Future<void> _abrirUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Opcional: Mostrar um SnackBar caso a URL seja inválida
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir o link: $url')),
      );
    }
  }
}