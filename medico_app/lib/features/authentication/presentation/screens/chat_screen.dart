// medico_app/lib/features/authentication/presentation/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:medico_app/features/chat/services/chat_service.dart';
import 'package:medico_app/features/chat/presentation/screens/detalhes_chat_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

// Usamos o 'SingleTickerProviderStateMixin' para a animação das abas
class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Inicializa o TabController com 3 abas
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final userProfile = authController.appUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(userProfile?.nome ?? 'ChatApp'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            child: Text(userProfile?.nome?.substring(0, 1) ?? 'U'),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Lógica de busca
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tela de Configurações ainda não implementada.')),
                );
              } else if (value == 'logout') {
                context.read<AuthController>().handleLogout();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('Configurações'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Sair'),
              ),
            ],
          ),
        ],
        // Adicionamos a TabBar aqui
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'CONVERSAS'),
            Tab(text: 'STATUS'),
            Tab(text: 'CHAMADAS'),
          ],
        ),
      ),
      // O corpo agora é um TabBarView
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Conteúdo da primeira aba (Conversas)
          ConversasTab(),
          // Conteúdo da segunda aba (Status)
          Center(child: Text('Tela de Status')),
          // Conteúdo da terceira aba (Chamadas)
          Center(child: Text('Tela de Chamadas')),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Ação do botão flutuante (ex: nova conversa)
        },
        child: const Icon(Icons.message),
      ),
    );
  }
}

// Widget para a aba de conversas
class ConversasTab extends StatelessWidget {
  const ConversasTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final userId = authController.user?.uid;
    final chatService = ChatService();

    if (userId == null) {
      return const Center(child: Text("Usuário não autenticado."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: chatService.getConversasStream(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Erro ao carregar conversas.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final conversas = snapshot.data!.docs;

        if (conversas.isEmpty) {
          return const Center(child: Text('Nenhuma conversa encontrada.'));
        }

        return ListView.builder(
          itemCount: conversas.length,
          itemBuilder: (context, index) {
            final conversaData = conversas[index].data() as Map<String, dynamic>;
            
            // Lógica para pegar o nome do outro usuário
            // (requer acesso aos dados dos usuários)
            final String nomeDestinatario = "Nome do Contato"; 
            
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(nomeDestinatario),
              subtitle: Text(conversaData['ultimaMensagem'] ?? ''),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetalhesChatScreen(
                      conversaId: conversas[index].id,
                      destinatarioNome: nomeDestinatario,
                      remetenteId: userId,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}