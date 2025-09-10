import 'package:flutter/material.dart';
import 'package:medico_app/features/medico/data/models/conteudo_educativo_model.dart';
import 'package:medico_app/features/medico/data/services/conteudo_educativo_service.dart';

class ConteudoEducativoScreen extends StatefulWidget {
  const ConteudoEducativoScreen({super.key});

  @override
  State<ConteudoEducativoScreen> createState() => _ConteudoEducativoScreenState();
}

class _ConteudoEducativoScreenState extends State<ConteudoEducativoScreen> {
  final ConteudoEducativoService _service = ConteudoEducativoService();
  ConteudoTipo? _filtro;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conteúdo Educativo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navegar para a tela de adicionar conteúdo
            },
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
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nenhum conteúdo disponível.'));
                }

                final conteudos = snapshot.data!.where((c) {
                  return _filtro == null || c.tipo == _filtro;
                }).toList();

                return ListView.builder(
                  itemCount: conteudos.length,
                  itemBuilder: (context, index) {
                    return _buildConteudoCard(conteudos[index]);
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8.0,
        children: ConteudoTipo.values.map((tipo) {
          return FilterChip(
            label: Text(tipo.name),
            selected: _filtro == tipo,
            onSelected: (selected) {
              setState(() {
                _filtro = selected ? tipo : null;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConteudoCard(ConteudoEducativo conteudo) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: Icon(_getIconForTipo(conteudo.tipo)),
        title: Text(conteudo.titulo),
        subtitle: Text(conteudo.descricao),
        onTap: () {
          // Abrir o conteúdo
        },
      ),
    );
  }

  IconData _getIconForTipo(ConteudoTipo tipo) {
    switch (tipo) {
      case ConteudoTipo.artigo:
        return Icons.article;
      case ConteudoTipo.video:
        return Icons.video_library;
      case ConteudoTipo.pdf:
        return Icons.picture_as_pdf;
    }
  }
}