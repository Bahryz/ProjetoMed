import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medico_app/features/medico/data/models/agendamento_models.dart';
import 'package:medico_app/features/medico/data/services/agenda_services.dart';


class AreaMedicaScreen extends StatelessWidget {
  const AreaMedicaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Cabeçalho
          const Text(
            'Painel de Controle',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Bem-vindo! Aqui estão suas tarefas e atalhos.',
            style: TextStyle(fontSize: 16, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),

          // Card da Agenda do Dia agora com dados dinâmicos
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
    final primaryColor = Theme.of(context).primaryColor;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: primaryColor),
                const SizedBox(width: 8),
                const Text('Agenda do Dia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            // Widget que constrói a lista de agendamentos de hoje
            _buildAgendamentosDeHoje(),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/agenda'),
                child: const Text('Ver Agenda Completa'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Novo widget com StreamBuilder para buscar dados em tempo real
  Widget _buildAgendamentosDeHoje() {
    final AgendaService agendaService = AgendaService();
    final hoje = DateTime.now();

    return StreamBuilder<List<Agendamento>>(
      stream: agendaService.getAgendamentosConfirmados(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ));
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Erro ao carregar agenda.'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Nenhuma consulta confirmada.'));
        }

        // Filtra a lista para pegar apenas agendamentos de hoje
        final agendamentosDeHoje = snapshot.data!.where((ag) {
          return ag.data.year == hoje.year &&
                 ag.data.month == hoje.month &&
                 ag.data.day == hoje.day;
        }).toList();

        if (agendamentosDeHoje.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text('Nenhuma consulta para hoje.'),
          ));
        }

        // Ordena os agendamentos por hora
        agendamentosDeHoje.sort((a, b) => a.data.compareTo(b.data));

        return Column(
          children: agendamentosDeHoje.map((agendamento) {
            return _buildAgendamentoItem(
              DateFormat('HH:mm').format(agendamento.data),
              agendamento.pacienteNome,
              agendamento.motivo,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAgendamentoItem(String horario, String nome, String motivo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Text(horario, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nome, style: const TextStyle(fontSize: 15)),
              Text(motivo, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
