import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Paleta de cores do app
const Color primaryColor = Color(0xFFB89453);
const Color accentColor = Color(0xFF4A4A4A);

class AreaMedicaScreen extends StatelessWidget {
  const AreaMedicaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Cabeçalho
          const Text(
            'Painel de Controle',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: accentColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Bem-vindo! Aqui estão suas tarefas e atalhos.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Card da Agenda do Dia
          _buildAgendaDoDiaCard(context),
          const SizedBox(height: 16),

          // Grid de Funcionalidades
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _FeatureCard(
                title: 'Meus Pacientes',
                icon: Icons.people_alt_rounded,
                color: Colors.blue,
                onTap: () => context.push('/lista-usuarios'),
              ),
              _FeatureCard(
                title: 'Conteúdo Educativo',
                icon: Icons.school_rounded,
                color: Colors.orange,
                onTap: () => context.push('/conteudo-educativo'),
              ),
              _FeatureCard(
                title: 'Feedbacks',
                icon: Icons.rate_review_rounded,
                color: Colors.purple,
                onTap: () => context.push('/feedbacks'),
              ),
              _FeatureCard(
                title: 'Meu Desempenho',
                icon: Icons.bar_chart_rounded,
                color: Colors.teal,
                onTap: () { /* TODO: Navegar para a tela de gráficos de desempenho */ },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card para a Agenda do Dia
  Widget _buildAgendaDoDiaCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: primaryColor),
                SizedBox(width: 8),
                Text('Agenda do Dia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            // MOCK DATA: Substituir por dados reais do agendamento
            _buildAgendamentoItem('10:00', 'José Machado', 'Consulta de Rotina'),
            _buildAgendamentoItem('11:00', 'Pedro Doutorado', 'Retorno'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/agenda'),
                child: const Text('Ver Agenda Completa', style: TextStyle(color: primaryColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendamentoItem(String horario, String nome, String motivo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(horario, style: const TextStyle(fontWeight: FontWeight.bold, color: accentColor)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nome, style: const TextStyle(fontSize: 15)),
              Text(motivo, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para os cards menores do grid
class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}