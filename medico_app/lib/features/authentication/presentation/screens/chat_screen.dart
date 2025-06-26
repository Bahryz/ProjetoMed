import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:medico_app/features/chat/presentation/screens/detalhes_chat_screen.dart';
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
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = "";

  // Paleta de cores profissional
  static const Color primaryColor = Color(0xFFB89453);
  static const Color accentColor = Color(0xFF4A4A4A);
  static const Color backgroundColor = Color(0xFFF7F7F7);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Buscar paciente...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16.0),
    );
  }

  List<Widget> _buildAppBarActions(bool isMedico) {
    if (isMedico) {
      return [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: _toggleSearch,
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout') {
              context.read<AuthController>().handleLogout();
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(value: 'settings', child: Text('Configurações')),
            const PopupMenuItem<String>(value: 'logout', child: Text('Sair')),
          ],
        ),
      ];
    } else {
      // Ações para paciente
      return [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout') {
              context.read<AuthController>().handleLogout();
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(value: 'logout', child: Text('Sair')),
          ],
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final userProfile = authController.appUser;
    // CORREÇÃO: Trocado 'tipoUsuario' por 'userType' para corresponder ao modelo AppUser.
    final isMedico = userProfile?.userType == 'medico';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: isMedico && _isSearching ? accentColor.withAlpha(220) : Colors.white,
        elevation: 1.0,
        title: _isSearching
            ? _buildSearchField()
            : Text(userProfile?.nome ?? 'Chat', style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: _isSearching ? Colors.white : accentColor),
        actionsIconTheme: IconThemeData(color: _isSearching ? Colors.white : accentColor),
        actions: _buildAppBarActions(isMedico),
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
        children: [
          ConversasTab(isMedico: isMedico, searchQuery: _searchQuery),
          const Center(child: Text('Tela de Status')),
          const Center(child: Text('Tela de Chamadas')),
        ],
      ),
      floatingActionButton: isMedico
          ? null // Médico não precisa de FAB aqui
          : FloatingActionButton(
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
  final bool isMedico;
  final String searchQuery;

  const ConversasTab({
    super.key,
    required this.isMedico,
    this.searchQuery = "",
  });

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final userId = authController.user?.uid;

    if (userId == null) {
      return const Center(child: Text("Usuário não autenticado."));
    }

    // Retorna a view apropriada baseada no tipo de usuário
    return isMedico
        ? _buildMedicoView(context, userId)
        : _buildPacienteView(context, userId);
  }

  // View para o Médico: Lista de todos os pacientes, com busca
  Widget _buildMedicoView(BuildContext context, String medicoId) {
    final userService = UserService();
    final chatService = ChatService();

    return StreamBuilder<List<AppUser>>(
      stream: userService.getPacientesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Erro ao carregar pacientes.'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Nenhum paciente encontrado.'));

        var pacientes = snapshot.data!;
        // Filtra a lista se houver uma busca ativa
        if (searchQuery.isNotEmpty) {
          pacientes = pacientes.where((p) => p.nome!.toLowerCase().contains(searchQuery.toLowerCase())).toList();
        }

        return ListView.builder(
          itemCount: pacientes.length,
          itemBuilder: (context, index) {
            final paciente = pacientes[index];
            final nomePaciente = paciente.nome ?? 'Paciente';
            final inicial = nomePaciente.isNotEmpty ? nomePaciente[0].toUpperCase() : '?';

            return Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFB89453).withAlpha(51),
                    child: Text(inicial, style: const TextStyle(color: Color(0xFFB89453), fontWeight: FontWeight.bold)),
                  ),
                  title: Text(nomePaciente, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Paciente'),
                  onTap: () async {
                    final conversaId = await chatService.getOrCreateConversation(medicoId, paciente.uid);
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalhesChatScreen(
                            conversaId: conversaId,
                            destinatarioNome: nomePaciente,
                            remetenteId: medicoId,
                          ),
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1, indent: 72, endIndent: 16),
              ],
            );
          },
        );
      },
    );
  }

  // View para o Paciente: Lista de conversas existentes
  Widget _buildPacienteView(BuildContext context, String pacienteId) {
    final chatService = ChatService();
    final userService = UserService();

    return StreamBuilder<QuerySnapshot>(
      stream: chatService.getConversasStream(pacienteId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Erro ao carregar conversas.'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Nenhuma conversa. Inicie uma com o Dr. Alvaro!'));

        final conversas = snapshot.data!.docs;

        return ListView.builder(
          itemCount: conversas.length,
          itemBuilder: (context, index) {
            final conversaData = conversas[index].data() as Map<String, dynamic>;
            final conversaId = conversas[index].id;
            
            final List<dynamic> participantes = conversaData['participantes'];
            final String destinatarioId = participantes.firstWhere((id) => id != pacienteId, orElse: () => '');

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
                        backgroundColor: const Color(0xFFB89453).withAlpha(51),
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
                              remetenteId: pacienteId,
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
