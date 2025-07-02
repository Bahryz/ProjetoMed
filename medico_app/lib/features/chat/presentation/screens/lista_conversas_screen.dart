import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/controllers/auth_controller.dart'; 
import '../../../authentication/data/models/app_user.dart';

class ListaConversasScreen extends ConsumerWidget {
  const ListaConversasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authController = ref.watch(authControllerProvider);
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
        title: const Text('Conversas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
            },
            tooltip: 'Configurações',
          ),
        ],
        automaticallyImplyLeading: false,
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
            return Center(child: Text('Erro ao carregar contatos: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            final String message = roleToFetch == 'paciente'
                ? 'Nenhum paciente encontrado.'
                : 'Nenhum médico disponível no momento.';
            return Center(child: Text(message));
          }

          final usersDocs = snapshot.data!.docs;

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
