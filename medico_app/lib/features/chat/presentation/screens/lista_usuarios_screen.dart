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
            // Se houver um erro no stream, mostre aqui
            debugPrint("Erro no StreamBuilder: ${snapshot.error}");
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
              if (medico.uid == currentUserId) return const SizedBox.shrink();
              
              final String inicial = medico.nome?.isNotEmpty == true ? medico.nome![0].toUpperCase() : 'M';

              return ListTile(
                leading: CircleAvatar(child: Text(inicial)),
                title: Text(medico.nome ?? 'Nome não disponível'),
                subtitle: const Text("Médico"),
                // --- ONTAP ATUALIZADO COM DIAGNÓSTICO ---
                onTap: () async {
                  try {
                    debugPrint("onTap iniciado para o médico: ${medico.nome}");
                    
                    debugPrint("Tentando criar ou obter a conversa...");
                    final conversaId = await chatService.getOrCreateConversation(currentUserId, medico.uid);
                    debugPrint("Conversa ID obtida com sucesso: $conversaId");

                    // Se chegou até aqui, a navegação deve ocorrer
                    debugPrint("Navegando para a tela de detalhes do chat...");
                    
                    // Usamos context.mounted para garantir que o widget ainda está na árvore
                    if (context.mounted) {
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
                      debugPrint("Navegação concluída.");
                    }

                  } catch (e) {
                    // Se qualquer erro acontecer no processo, será impresso aqui
                    debugPrint("!!!!!!!!!! ERRO NO ONTAP !!!!!!!!!!");
                    debugPrint(e.toString());
                    if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Erro ao iniciar conversa: $e"))
                      );
                    }
                  }
                },
                // --- FIM DO ONTAP ATUALIZADO ---
              );
            },
          );
        },
      ),
    );
  }
}