import 'package:cloud_firestore/cloud_firestore.dart';


enum AgendamentoStatus { pendente, confirmado, recusado, cancelado }

class Agendamento {
  final String id;
  final String pacienteId;
  final String pacienteNome;
  final DateTime data;
  final String motivo;
  final AgendamentoStatus status;

  Agendamento({
    required this.id,
    required this.pacienteId,
    required this.pacienteNome,
    required this.data,
    required this.motivo,
    required this.status,
  });

  factory Agendamento.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Agendamento(
      id: doc.id,
      pacienteId: data['pacienteId'] ?? '',
      pacienteNome: data['pacienteNome'] ?? 'Nome não informado',
      data: (data['data'] as Timestamp).toDate(),
      motivo: data['motivo'] ?? 'Motivo não informado',
      status: AgendamentoStatus.values.firstWhere(
        (e) => e.toString() == 'AgendamentoStatus.${data['status']}',
        orElse: () => AgendamentoStatus.pendente,
      ),
    );
  }
}