// medico_app/lib/features/authentication/presentation/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';

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
class ConversasTab extends StatefulWidget {
  const ConversasTab({super.key});

  @override
  State<ConversasTab> createState() => _ConversasTabState();
}

class _ConversasTabState extends State<ConversasTab> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'sender': 'other', 'text': 'Olá! Como você está se sentindo hoje?'},
    {'sender': 'me', 'text': 'Olá, doutor! Estou me sentindo um pouco melhor.'},
    {'sender': 'other', 'text': 'Ótimo! Continue com a medicação.'},
  ];

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      setState(() {
        _messages.add({'sender': 'me', 'text': _messageController.text});
        _messageController.clear();
      });
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _messages.add({'sender': 'other', 'text': 'Entendido. Continue seguindo as recomendações.'});
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Para simplificar, estamos usando uma lista estática.
    // O ideal seria ter uma lista de conversas aqui.
    return ListView.builder(
      itemCount: 1, // Apenas para simular uma conversa na lista
      itemBuilder: (context, index) {
        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.person),
          ),
          title: const Text('Dr. Silva'),
          subtitle: Text(_messages.last['text']!), // Mostra a última mensagem
          trailing: const Text('19:45'),
          onTap: () {
            // Ao clicar, poderia abrir a tela de chat detalhada
            // Por enquanto, vamos manter a UI de chat simulada aqui
            // mas o ideal é navegar para uma nova tela
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: 0.9,
                  builder: (_, controller) => Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: controller,
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isMe = message['sender'] == 'me';
                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4.0),
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.blue[100] : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Text(message['text']!),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Digite uma mensagem...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                ),
                                onSubmitted: (value) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: _sendMessage,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}