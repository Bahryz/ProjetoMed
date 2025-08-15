import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:medico_app/features/chat/services/chat_service.dart';
import 'package:provider/provider.dart';

class ListaConversasScreen extends StatelessWidget {
  const ListaConversasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final currentUser = authController.user;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String roleToFetch =
        currentUser.userType == 'medico' ? 'paciente' : 'medico';

    return Scaffold(
      appBar: AppBar(
        title: Text(roleToFetch == 'paciente' ? 'Pacientes' : 'Médicos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthController>().handleLogout();
            },
            tooltip: 'Sair',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('userType', isEqualTo: roleToFetch)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            final String message = roleToFetch == 'paciente'
                ? 'Nenhum paciente encontrado.'
                : 'Nenhum médico disponível.';
            return Center(child: Text(message));
          }

          final usersDocs = snapshot.data!.docs;
          final chatService = ChatService();

          return ListView.builder(
            itemCount: usersDocs.length,
            itemBuilder: (context, index) {
              final userDoc = usersDocs[index];
              final otherUser = AppUser.fromDocumentSnapshot(userDoc);

              return ListTile(
                leading: CircleAvatar(
                  child: Text(otherUser.nome.isNotEmpty ? otherUser.nome[0].toUpperCase() : '?'),
                ),
                title: Text(otherUser.nome),
                subtitle: Text(
                  otherUser.userType.substring(0, 1).toUpperCase() +
                      otherUser.userType.substring(1),
                ),
                onTap: () async {
                  try {
                    // Garante que a conversa exista no Firestore antes de navegar
                    await chatService.getOrCreateConversation(
                      currentUser.uid,
                      otherUser.uid,
                    );

                    // Navega para a rota do chat
                    if (context.mounted) {
                      context.go('/chat', extra: otherUser);
                    }
                  } catch (e) {
                    // Mostra um erro para o usuário se a criação da conversa falhar
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Não foi possível iniciar o chat: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}