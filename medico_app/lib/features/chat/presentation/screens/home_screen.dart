// bahryz/projetomed/ProjetoMed-6502db256f60032b63be3b6019c0ea07dd298519/medico_app/lib/features/chat/presentation/screens/home_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:medico_app/features/chat/presentation/screens/lista_conversas_screen.dart';
import 'package:medico_app/features/chat/services/chat_service.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:medico_app/features/documentos/presentation/screens/documentos_screen.dart';

// Paleta de cores definida para ser usada em toda a tela.
const Color primaryColor = Color(0xFFB89453);
const Color accentColor = Color(0xFF4A4A4A);

/// Tela principal que decide qual layout mostrar (Médico ou Paciente).
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
    // Define as abas específicas para o médico
    final List<Tab> tabs = [
      const Tab(text: 'CHATS'),
      const Tab(text: 'ÁREA MÉDICA'),
      const Tab(text: 'DOCUMENTOS'),
      const Tab(text: 'CHAMADAS'),
    ];

    // Define as telas correspondentes para cada aba
    final List<Widget> tabViews = [
      const ListaConversasScreen(),
      const _PlaceholderScreen(title: 'Área Médica'),
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
        backgroundColor: primaryColor,
        tooltip: 'Iniciar nova conversa',
        child: const Icon(Icons.add_comment_rounded, color: Colors.white),
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
    // Define as abas específicas para o paciente
    final List<Tab> tabs = [
      const Tab(text: 'MÉDICO'),
      const Tab(text: 'CHATS'),
      const Tab(text: 'DOCUMENTOS'),
      const Tab(text: 'CHAMADAS'),
    ];

    // Define as telas correspondentes
    final List<Widget> tabViews = [
      _PatientDoctorTab(currentUser: currentUser),
      const ListaConversasScreen(), // A tela de chats é incluída aqui
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

/// Widget reutilizável para construir o Scaffold com abas, AppBar e Drawer.
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
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: accentColor),
        title: Text(title,
            style:
                const TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
        elevation: 1.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implementar lógica de busca
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'config') {
                context.push('/configuracoes');
              }
              // TODO: Implementar outras opções
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
          tabs: tabs,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: primaryColor,
          indicatorWeight: 3.0,
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

/// O menu lateral que abre ao clicar no ícone de hambúrguer.
class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: primaryColor,
            ),
            child: Text(
              'Med App',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Meu Perfil'),
            onTap: () {
              // TODO: Navegar para a tela de perfil
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () => context.push('/configuracoes'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () async {
              await context.read<AuthController>().handleLogout();
            },
          ),
        ],
      ),
    );
  }
}

/// Tela de exemplo para abas que ainda não foram implementadas.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, color: Colors.grey.shade400, size: 60),
          const SizedBox(height: 16),
          Text(
            'Tela de $title',
            style: const TextStyle(fontSize: 22, color: Colors.black54),
          ),
          const Text(
            'Em desenvolvimento',
            style: TextStyle(fontSize: 16, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

/// Aba específica do paciente para encontrar e iniciar conversa com o médico.
class _PatientDoctorTab extends StatelessWidget {
  final AppUser currentUser;
  const _PatientDoctorTab({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'medico')
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhum médico encontrado.'));
        }

        final medicoDoc = snapshot.data!.docs.first;
        final medico = AppUser.fromDocumentSnapshot(medicoDoc);

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                    radius: 50, child: Icon(Icons.medical_services, size: 50)),
                const SizedBox(height: 20),
                Text(
                  'Dr(a). ${medico.nome}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'CRM: ${medico.crm ?? 'Não informado'}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text('Iniciar Conversa',
                      style: TextStyle(color: Colors.white)),
                  onPressed: () async {
                    final chatService = ChatService();
                    await chatService.getOrCreateConversation(
                      currentUser.uid,
                      medico.uid,
                    );
                    if (!context.mounted) return;
                    context.push('/chat', extra: medico);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}