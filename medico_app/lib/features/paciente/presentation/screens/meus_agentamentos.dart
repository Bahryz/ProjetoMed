import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:medico_app/medico/data/models/agendamento_models.dart';
import 'package:medico_app/medico/data/services/agenda_services.dart';
import 'package:provider/provider.dart';

const Color primaryColor = Color(0xFFB89453);

class MeusAgendamentosScreen extends StatelessWidget {
  const MeusAgendamentosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final paciente = context.read<AuthController>().user;
    if (paciente == null) {
      return const Scaffold(body: Center(child: Text("Usuário não encontrado.")));
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meus Agendamentos'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'PRÓXIMOS'),
              Tab(text: 'PENDENTES'),
              Tab(text: 'HISTÓRICO'),
            ],
          ),
        ),
        body: StreamBuilder<List<Agendamento>>(
          stream: AgendaService().getAgendamentosPorPaciente(paciente.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Erro ao carregar agendamentos: ${snapshot.error}"));
            }
            final todosAgendamentos = snapshot.data ?? [];

            final confirmados = todosAgendamentos.where((a) => a.status == AgendamentoStatus.confirmado && a.data.isAfter(DateTime.now())).toList();
            final pendentes = todosAgendamentos.where((a) => a.status == AgendamentoStatus.pendente).toList();
            final historico = todosAgendamentos.where((a) => a.status != AgendamentoStatus.pendente && a.data.isBefore(DateTime.now())).toList();

            return TabBarView(
              children: [
                _buildAgendamentoList(confirmados, "Nenhuma consulta confirmada."),
                _buildAgendamentoList(pendentes, "Nenhuma solicitação pendente."),
                _buildAgendamentoList(historico, "Nenhum histórico de consultas."),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/solicitar-agendamento'),
          label: const Text('Solicitar Consulta'),
          icon: const Icon(Icons.add),
          backgroundColor: primaryColor,
        ),
      ),
    );
  }

  Widget _buildAgendamentoList(List<Agendamento> agendamentos, String emptyMessage) {
    if (agendamentos.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return ListView.builder(
      itemCount: agendamentos.length,
      itemBuilder: (context, index) {
        final agendamento = agendamentos[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(_getStatusIcon(agendamento.status), color: _getStatusColor(agendamento.status)),
            title: Text(agendamento.motivo),
            subtitle: Text(DateFormat('dd/MM/yyyy \'às\' HH:mm').format(agendamento.data)),
            trailing: Text(
              agendamento.status.name.toUpperCase(),
              style: TextStyle(color: _getStatusColor(agendamento.status), fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(AgendamentoStatus status) {
    switch (status) {
      case AgendamentoStatus.confirmado: return Icons.check_circle;
      case AgendamentoStatus.pendente: return Icons.hourglass_top;
      case AgendamentoStatus.recusado: return Icons.cancel;
      case AgendamentoStatus.cancelado: return Icons.do_not_disturb_on;
    }
  }

  Color _getStatusColor(AgendamentoStatus status) {
    switch (status) {
      case AgendamentoStatus.confirmado: return Colors.green;
      case AgendamentoStatus.pendente: return Colors.orange;
      case AgendamentoStatus.recusado: return Colors.red;
      case AgendamentoStatus.cancelado: return Colors.grey;
    }
  }
}