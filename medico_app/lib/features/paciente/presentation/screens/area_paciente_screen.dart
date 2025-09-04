import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AreaPacienteScreen extends StatelessWidget {
  const AreaPacienteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Card de Agendamento atualizado para levar à tela de gerenciamento
          _FeatureCard(
            title: 'Meus Agendamentos',
            subtitle: 'Veja suas consultas e solicite novos horários.',
            icon: Icons.calendar_month_rounded,
            color: Colors.blue,
            onTap: () => context.push('/meus-agendamentos'),
          ),
          const SizedBox(height: 16),
          // Outros cards...
          _FeatureCard(
            title: 'Minha Evolução',
            subtitle: 'Acompanhe seus dados de saúde.',
            icon: Icons.trending_up,
            color: Colors.green,
            onTap: () { /* TODO: Navegar para tela de evolução */},
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            title: 'Educação em Saúde',
            subtitle: 'Artigos e vídeos para cuidar de você.',
            icon: Icons.school_rounded,
            color: Colors.orange,
            onTap: () { /* TODO: Navegar para tela de educação */ },
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para os cards
class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, size: 28, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}