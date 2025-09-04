import 'package:cloud_firestore/cloud_firestore.dart';
// Corrigindo o caminho do import para o local correto do modelo
import 'package:medico_app/medico/data/models/agendamento_models.dart'; 

class AgendaService {
  final CollectionReference _agendamentosCollection =
      FirebaseFirestore.instance.collection('agendamentos');

  // Busca agendamentos com um status específico (pendente, confirmado, etc.)
  Stream<List<Agendamento>> getAgendamentosPorStatus(AgendamentoStatus status) {
    return _agendamentosCollection
        .where('status', isEqualTo: status.name)
        .orderBy('data')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Agendamento.fromFirestore(doc)).toList();
    });
  }

  // Busca todos os agendamentos confirmados para popular o calendário
  Stream<List<Agendamento>> getAgendamentosConfirmados() {
    return getAgendamentosPorStatus(AgendamentoStatus.confirmado);
  }

  // Atualiza o status de um agendamento (Aprovar ou Recusar)
  Future<void> atualizarStatusAgendamento(String id, AgendamentoStatus novoStatus) async {
    await _agendamentosCollection.doc(id).update({'status': novoStatus.name});
  }

  // 👇 MÉTODO ADICIONADO PARA A ÁREA DO PACIENTE
  /// Busca todos os agendamentos de um paciente específico, ordenados por data.
  Stream<List<Agendamento>> getAgendamentosPorPaciente(String pacienteId) {
    return _agendamentosCollection
        .where('pacienteId', isEqualTo: pacienteId)
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Agendamento.fromFirestore(doc)).toList();
    });
  }
}