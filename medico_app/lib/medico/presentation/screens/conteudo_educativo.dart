import 'package:flutter/material.dart';

class ConteudoEducativoScreen extends StatelessWidget {
  const ConteudoEducativoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conteúdo Educativo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () {
              // TODO: Lógica para abrir um formulário e adicionar novo conteúdo
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Abrindo formulário para novo conteúdo...'))
              );
            },
            tooltip: 'Adicionar Novo Conteúdo',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TODO: Substituir por uma lista real vinda do Firebase
          _buildConteudoCard(
            'Nutrição e Bem-estar', 
            'Dicas para uma alimentação saudável e equilibrada no dia a dia.',
            Icons.restaurant_menu
          ),
          _buildConteudoCard(
            'Saúde Mental', 
            'A importância do cuidado com a mente para a saúde integrativa.',
            Icons.self_improvement
          ),
        ],
      ),
    );
  }

  Widget _buildConteudoCard(String title, String subtitle, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.teal),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.edit),
        onTap: () { /* TODO: Lógica para editar o conteúdo */ },
      ),
    );
  }
}