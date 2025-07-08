import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:provider/provider.dart';

class ListaConversasScreen extends StatelessWidget {
  const ListaConversasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Acessa o AuthController usando Provider para obter o usuário atual.
    final authController = context.watch<AuthController>();
    final currentUser = authController.user;

    // Mostra um indicador de carregamento se o usuário ainda não foi carregado.
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Determina qual tipo de usuário deve ser buscado (médicos ou pacientes).
    final String roleToFetch =
        currentUser.userType == 'medico' ? 'paciente' : 'medico';

    return Scaffold(
      appBar: AppBar(
        title: Text(roleToFetch == 'paciente' ? 'Pacientes' : 'Médicos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // CORREÇÃO: Chamada padronizada para o método 'handleLogout'.
              context.read<AuthController>().handleLogout();
            },
            tooltip: 'Sair',
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Cria um stream que busca os usuários do tipo desejado no Firestore.
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

          // Constrói a lista de usuários.
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
                onTap: () {
                  // NAVEGAÇÃO: Ao tocar, vai para a rota '/chat'
                  // e passa o objeto 'otherUser' como argumento.
                  context.go('/chat', extra: otherUser);
                },
              );
            },
          );
        },
      ),
    );
  }
}
