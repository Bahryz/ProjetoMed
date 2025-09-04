// medico_app/lib/features/chat/presentation/screens/home_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:medico_app/features/medico/presentation/screens/area_medica_screen.dart';
import 'package:medico_app/features/chat/presentation/screens/lista_conversas_screen.dart';
import 'package:medico_app/features/chat/services/chat_service.dart';
import 'package:medico_app/features/documentos/presentation/screens/documentos_screen.dart';
import 'package:medico_app/features/paciente/presentation/screens/area_paciente_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  final AppUser currentUser;

  const HomeScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    if (currentUser.userType == 'medico') {
      return const _DoctorHomeScreen();
    } else {
      return _PatientHomeScreen(currentUser: currentUser);
    }
  }
}

// --- ESTRUTURA PARA MÉDICOS ---
class _DoctorHomeScreen extends StatelessWidget {
  const _DoctorHomeScreen();

  @override
  Widget build(BuildContext context) {
    final List<Tab> tabs = [
      const Tab(text: 'CHATS'),
      const Tab(text: 'ÁREA MÉDICA'),
      const Tab(text: 'DOCUMENTOS'),
      const Tab(text: 'CHAMADAS'),
    ];

    final List<Widget> tabViews = [
      const ListaConversasScreen(),
      const AreaMedicaScreen(),
      const DocumentosScreen(),
      const _PlaceholderScreen(title: 'Chamadas'),
    ];

    return _buildScaffoldWithTabs(
      context: context,
      title: 'Painel do Médico',
      tabs: tabs,
      tabViews: tabViews,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/lista-usuarios'),
        tooltip: 'Iniciar nova conversa',
        child: const Icon(Icons.add_comment_rounded),
      ),
    );
  }
}

// --- ESTRUTURA PARA PACIENTES ---
class _PatientHomeScreen extends StatelessWidget {
  final AppUser currentUser;
  const _PatientHomeScreen({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final List<Tab> tabs = [
      const Tab(text: 'MÉDICO'),
      const Tab(text: 'ÁREA DO PACIENTE'),
      const Tab(text: 'DOCUMENTOS'),
      const Tab(text: 'CHAMADAS'),
    ];

    final List<Widget> tabViews = [
      _PatientDoctorAndChatTab(currentUser: currentUser),
      const AreaPacienteScreen(),
      const DocumentosScreen(),
      const _PlaceholderScreen(title: 'Chamadas'),
    ];

    return _buildScaffoldWithTabs(
      context: context,
      title: 'Área do Paciente',
      tabs: tabs,
      tabViews: tabViews,
    );
  }
}

// --- WIDGETS REUTILIZÁVEIS ---

Widget _buildScaffoldWithTabs({
  required BuildContext context,
  required String title,
  required List<Tab> tabs,
  required List<Widget> tabViews,
  Widget? floatingActionButton,
}) {
  return DefaultTabController(
    length: tabs.length,
    child: Scaffold(
      appBar: AppBar(
        title: Text(title), // O título agora usará o estilo do tema
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'config') {
                context.push('/configuracoes');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'config',
                child: Text('Configurações'),
              ),
              const PopupMenuItem<String>(
                value: 'privacy',
                child: Text('Privacidade'),
              ),
              const PopupMenuItem<String>(
                value: 'help',
                child: Text('Ajuda'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          tabs: tabs, // As cores da TabBar virão do tema
        ),
      ),
      drawer: const _AppDrawer(),
      body: TabBarView(
        children: tabViews,
      ),
      floatingActionButton: floatingActionButton,
    ),
  );
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Text(
              'Med App',
              style: TextStyle(
                color: Colors.black, // Texto preto para contrastar com dourado
                fontSize: 24,
                fontWeight: FontWeight.bold
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Meu Perfil'),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () {
               Navigator.of(context).pop();
              context.push('/configuracoes');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () async {
              Navigator.of(context).pop();
              await context.read<AuthController>().handleLogout();
            },
          ),
        ],
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, color: Colors.grey.shade700, size: 60),
          const SizedBox(height: 16),
          Text(
            'Tela de $title',
            style: const TextStyle(fontSize: 22, color: Colors.white70),
          ),
          const Text(
            'Em desenvolvimento',
            style: TextStyle(fontSize: 16, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class _PatientDoctorAndChatTab extends StatelessWidget {
  final AppUser currentUser;
  const _PatientDoctorAndChatTab({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDoctorInfoCard(context),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 8),
              const Text(
                "Minhas Conversas",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const Expanded(
          child: ListaConversasScreen(),
        ),
      ],
    );
  }

  Widget _buildDoctorInfoCard(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'medico')
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Card(
              child: ListTile(title: Text("Nenhum médico encontrado.")));
        }

        final medicoDoc = snapshot.data!.docs.first;
        final medico = AppUser.fromDocumentSnapshot(medicoDoc);

        return Card(
          margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(Icons.medical_services,
                      size: 40, color: primaryColor),
                ),
                const SizedBox(height: 12),
                Text(
                  'Dr(a). ${medico.nome}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'CRM: ${medico.crm ?? 'Não informado'}',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.chat),
                  label: const Text('Conversar com o Médico'),
                  onPressed: () async {
                    final chatService = ChatService();
                    await chatService.getOrCreateConversation(
                      currentUser.uid,
                      medico.uid,
                    );
                    if (!context.mounted) return;
                    context.push('/chat', extra: medico);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}