import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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

    final chatService = ChatService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversas'),
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
        // Passo 1: Usar o stream que busca as CONVERSAS do usuário atual
        stream: chatService.getConversasStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('Nenhuma conversa encontrada.\nInicie uma conversa com um paciente.'));
          }

          final conversasDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: conversasDocs.length,
            itemBuilder: (context, index) {
              final conversaDoc = conversasDocs[index];
              return _ConversationTile(
                conversaDoc: conversaDoc,
                currentUser: currentUser,
              );
            },
          );
        },
      ),
    );
  }
}

// Widget auxiliar para manter o código organizado
class _ConversationTile extends StatelessWidget {
  final DocumentSnapshot conversaDoc;
  final AppUser currentUser;

  const _ConversationTile({
    required this.conversaDoc,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final data = conversaDoc.data() as Map<String, dynamic>;
    final List<dynamic> participantes = data['participantes'];
    
    // Passo 2: Descobrir qual participante é o paciente
    final otherUserId =
        participantes.firstWhere((id) => id != currentUser.uid, orElse: () => '');

    if (otherUserId.isEmpty) {
      return const SizedBox.shrink(); // Retorna um widget vazio se algo der errado
    }

    // Passo 3: Buscar os dados do paciente usando um FutureBuilder
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          // Pode-se colocar um shimmer/loading effect aqui
          return const ListTile(title: Text('Carregando...'));
        }

        final otherUser = AppUser.fromDocumentSnapshot(userSnapshot.data!);
        final ultimaMensagem = data['ultimaMensagem'] ?? 'Nenhuma mensagem';
        final timestamp = data['timestampUltimaMensagem'] as Timestamp?;
        
        String tempo = '';
        if (timestamp != null) {
          tempo = DateFormat('HH:mm').format(timestamp.toDate());
        }

        return ListTile(
          leading: CircleAvatar(
            child: Text(
                otherUser.nome.isNotEmpty ? otherUser.nome[0].toUpperCase() : '?'),
          ),
          title: Text(otherUser.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            ultimaMensagem,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(tempo),
          onTap: () {
            // A navegação continua a mesma, agora com os dados corretos
            context.go('/chat', extra: otherUser);
          },
        );
      },
    );
  }
}