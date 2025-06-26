import 'package:flutter/material.dart';
import 'package:medico_app/features/chat/presentation/screens/detalhes_chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:medico_app/features/chat/presentation/screens/lista_usuarios_screen.dart';
import 'package:medico_app/features/chat/services/chat_service.dart';
import 'package:medico_app/features/chat/services/user_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Definindo a paleta de cores baseada na tela de login
  static const Color primaryColor = Color(0xFFB89453);
  static const Color accentColor = Color(0xFF4A4A4A);
  static const Color backgroundColor = Color(0xFFF7F7F7);

  @override
  void initState() {
    super.initState();
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1.0,
        title: Text(
          userProfile?.nome ?? 'Chat',
          style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: accentColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Lógica de busca
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          indicatorWeight: 3.0,
          tabs: const [
            Tab(text: 'CONVERSAS'),
            Tab(text: 'STATUS'),
            Tab(text: 'CHAMADAS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ConversasTab(),
          Center(child: Text('Tela de Status')),
          Center(child: Text('Tela de Chamadas')),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ListaUsuariosScreen()),
          );
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add_comment_rounded, color: Colors.white),
      ),
    );
  }
}

class ConversasTab extends StatelessWidget {
  const ConversasTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final userId = authController.user?.uid;
    final chatService = ChatService();
    final userService = UserService();

    if (userId == null) {
      return const Center(child: Text("Usuário não autenticado."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: chatService.getConversasStream(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Erro ao carregar conversas.'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final conversas = snapshot.data!.docs;
        if (conversas.isEmpty) return const Center(child: Text('Nenhuma conversa encontrada. Inicie uma nova!'));

        return ListView.builder(
          itemCount: conversas.length,
          itemBuilder: (context, index) {
            final conversaData = conversas[index].data() as Map<String, dynamic>;
            final conversaId = conversas[index].id;
            
            final List<dynamic> participantes = conversaData['participantes'];
            final String destinatarioId = participantes.firstWhere((id) => id != userId, orElse: () => '');

            if (destinatarioId.isEmpty) return const SizedBox.shrink();

            return FutureBuilder<AppUser?>(
              future: userService.getUserData(destinatarioId),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(title: Text("Carregando..."), leading: CircleAvatar());
                }
                
                final destinatario = userSnapshot.data;
                final nomeDestinatario = destinatario?.nome ?? 'Contato';
                final inicial = nomeDestinatario.isNotEmpty ? nomeDestinatario[0].toUpperCase() : '?';

                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFB89453).withOpacity(0.2),
                        child: Text(inicial, style: const TextStyle(color: Color(0xFFB89453), fontWeight: FontWeight.bold)),
                      ),
                      title: Text(nomeDestinatario, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        conversaData['ultimaMensagem'] ?? 'Toque para conversar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetalhesChatScreen(
                              conversaId: conversaId,
                              destinatarioNome: nomeDestinatario,
                              remetenteId: userId,
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 72, endIndent: 16),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}