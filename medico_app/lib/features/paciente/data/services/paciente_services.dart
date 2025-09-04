import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';

class PacienteService {
  final CollectionReference _agendamentosCollection =
      FirebaseFirestore.instance.collection('agendamentos');

  /// Cria uma nova solicitação de agendamento no Firestore
  Future<void> solicitarAgendamento({
    required AppUser paciente,
    required DateTime data,
    required String motivo,
  }) async {
    await _agendamentosCollection.add({
      'pacienteId': paciente.uid,
      'pacienteNome': paciente.nome,
      'data': Timestamp.fromDate(data),
      'motivo': motivo,
      'status': 'pendente', // O status inicial é sempre pendente
    });
  }
}