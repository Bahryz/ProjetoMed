import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medico_app/features/medico/data/models/agendamento_models.dart';
import 'package:medico_app/features/medico/data/services/agenda_services.dart';
import 'package:table_calendar/table_calendar.dart';

const Color primaryColor = Color(0xFFB89453);

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final AgendaService _agendaService = AgendaService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda Completa')),
      body: Column(
        children: [
          // Seção de Solicitações Pendentes
          _buildSolicitacoesPendentes(),

          // Calendário com agendamentos confirmados
          _buildCalendarioConfirmados(),
        ],
      ),
    );
  }

  // Widget para a lista de solicitações pendentes (com tratamento de erro e loading)
  Widget _buildSolicitacoesPendentes() {
    return StreamBuilder<List<Agendamento>>(
      stream: _agendaService.getAgendamentosPorStatus(AgendamentoStatus.pendente),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Erro ao carregar solicitações: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: const Text("Nenhuma solicitação pendente.", textAlign: TextAlign.center),
          );
        }
        final solicitacoes = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(8.0),
          height: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text("Solicitações Pendentes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: solicitacoes.length,
                  itemBuilder: (context, index) {
                    final agendamento = solicitacoes[index];
                    return Card(
                      child: ListTile(
                        title: Text(agendamento.pacienteNome),
                        subtitle: Text(DateFormat('dd/MM/yyyy \'às\' HH:mm').format(agendamento.data)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () => _agendaService.atualizarStatusAgendamento(agendamento.id, AgendamentoStatus.confirmado),
                              tooltip: 'Aprovar',
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _agendaService.atualizarStatusAgendamento(agendamento.id, AgendamentoStatus.recusado),
                              tooltip: 'Recusar',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
            ],
          ),
        );
      },
    );
  }

  // Widget para o calendário e a lista de eventos confirmados
  Widget _buildCalendarioConfirmados() {
    return StreamBuilder<List<Agendamento>>(
      stream: _agendaService.getAgendamentosConfirmados(),
      builder: (context, snapshot) {
        final eventos = snapshot.data ?? [];
        
        Map<DateTime, List<Agendamento>> eventosPorDia = {};
        for (var evento in eventos) {
          final dia = DateTime.utc(evento.data.year, evento.data.month, evento.data.day);
          if (eventosPorDia[dia] == null) {
            eventosPorDia[dia] = [];
          }
          eventosPorDia[dia]!.add(evento);
        }

        List<Agendamento> getEventosDoDia(DateTime day) {
          return eventosPorDia[DateTime.utc(day.year, day.month, day.day)] ?? [];
        }

        return Expanded(
          child: Column(
            children: [
              TableCalendar(
                locale: 'pt_BR',
                firstDay: DateTime.utc(2020),
                lastDay: DateTime.utc(2030),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: getEventosDoDia,
                 calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                    selectedDecoration: BoxDecoration(color: Color(0xFF4A4A4A), shape: BoxShape.circle),
                 ),
                 headerStyle: const HeaderStyle(titleCentered: true, formatButtonVisible: false),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: [
                    if (_selectedDay != null)
                      ...getEventosDoDia(_selectedDay!).map((ag) => ListTile(
                            leading: const Icon(Icons.event_available, color: primaryColor),
                            title: Text(ag.pacienteNome),
                            subtitle: Text("${DateFormat('HH:mm').format(ag.data)} - ${ag.motivo}"),
                          )),
                    if (_selectedDay == null || getEventosDoDia(_selectedDay!).isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text("Nenhuma consulta confirmada para este dia.")),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}