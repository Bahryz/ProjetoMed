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

// --- ESTRUTURA PARA MÉDICOS (ATUALIZADA) ---
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

    // Define as telas correspondentes, agora com a AreaMedicaScreen
    final List<Widget> tabViews = [
      const ListaConversasScreen(),
      const AreaMedicaScreen(), // Usando o dashboard funcional do médico
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

// --- ESTRUTURA PARA PACIENTES (ATUALIZADA) ---
class _PatientHomeScreen extends StatelessWidget {
  final AppUser currentUser;
  const _PatientHomeScreen({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    // Define as novas abas, com "ÁREA DO PACIENTE"
    final List<Tab> tabs = [
      const Tab(text: 'MÉDICO'),
      const Tab(text: 'ÁREA DO PACIENTE'),
      const Tab(text: 'DOCUMENTOS'),
      const Tab(text: 'CHAMADAS'),
    ];

    // Define as telas correspondentes
    final List<Widget> tabViews = [
      _PatientDoctorAndChatTab(currentUser: currentUser), // Aba unificada de Médico + Chats
      const AreaPacienteScreen(), // A nova tela do paciente
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
              // Fecha o drawer antes de navegar para uma melhor UX
              Navigator.of(context).pop();
              // Navega para a nova tela de perfil
              context.push('/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () {
               // Fecha o drawer antes de navegar
              Navigator.of(context).pop();
              context.push('/configuracoes');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () async {
              // Fecha o drawer
              Navigator.of(context).pop();
              // Executa o logout
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

/// Aba unificada do paciente para informações do médico e chats.
class _PatientDoctorAndChatTab extends StatelessWidget {
  final AppUser currentUser;
  const _PatientDoctorAndChatTab({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    // Usamos um Column para empilhar as informações do médico e a lista de conversas
    return Column(
      children: [
        // Card com informações e botão para iniciar conversa
        _buildDoctorInfoCard(context),
        const Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded, color: accentColor),
              SizedBox(width: 8),
              Text(
                "Minhas Conversas",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentColor),
              ),
            ],
          ),
        ),
        // A lista de conversas existentes fica aqui
        Expanded(
          child: ListaConversasScreen(), // Reutilizamos a tela de conversas aqui
        ),
      ],
    );
  }

  // Widget para exibir o card do médico
  Widget _buildDoctorInfoCard(BuildContext context) {
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
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: const Icon(Icons.medical_services,
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
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text('Conversar com o Médico',
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
                        horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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