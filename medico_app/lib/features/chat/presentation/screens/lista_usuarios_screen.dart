// lib/features/chat/presentation/screens/lista_usuarios_screen.dart

import 'package:flutter/material.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/chat/services/chat_service.dart';
import 'package:medico_app/features/chat/services/user_service.dart';
import 'package:medico_app/features/chat/presentation/screens/detalhes_chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';

class ListaUsuariosScreen extends StatelessWidget {
  const ListaUsuariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final chatService = ChatService();
    final authController = context.read<AuthController>();
    final currentUserId = authController.user?.uid;

    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text("Erro: Usuário não encontrado.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Nova Conversa'),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: userService.getMedicosStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar usuários.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final medicos = snapshot.data!;

          return ListView.builder(
            itemCount: medicos.length,
            itemBuilder: (context, index) {
              final medico = medicos[index];

              if (medico.uid == currentUserId) {
                return const SizedBox.shrink();
              }
              
              // --- LINHA CORRIGIDA ---
              // Usamos '??' para fornecer um valor padrão se nome for nulo,
              // e '?.' para só chamar substring se nome não for nulo.
              final String inicial = medico.nome?.isNotEmpty == true ? medico.nome![0].toUpperCase() : 'M';

              return ListTile(
                leading: CircleAvatar(child: Text(inicial)),
                title: Text(medico.nome ?? 'Nome não disponível'),
                subtitle: const Text("Médico"),
                onTap: () async {
                  final conversaId = await chatService.getOrCreateConversation(currentUserId, medico.uid);
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetalhesChatScreen(
                        conversaId: conversaId,
                        destinatarioNome: medico.nome ?? 'Médico',
                        remetenteId: currentUserId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}