import 'package:flutter/material.dart';

class FeedbacksScreen extends StatelessWidget {
  const FeedbacksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedbacks Recebidos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFeedbackCard(
            'José Machado',
            5,
            'Excelente atendimento, muito atencioso e claro nas explicações.',
            DateTime.now().subtract(const Duration(days: 2))
          ),
          _buildFeedbackCard(
            'Pedro Doutorado',
            4,
            'A consulta foi ótima, mas a recepção demorou um pouco.',
            DateTime.now().subtract(const Duration(days: 5))
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(String paciente, int nota, String comentario, DateTime data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(paciente, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: List.generate(5, (index) => Icon(
                    index < nota ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  )),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(comentario),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '${data.day}/${data.month}/${data.year}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}