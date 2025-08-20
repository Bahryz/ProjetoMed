import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:medico_app/features/chat/presentation/screens/lista_conversas_screen.dart';
import 'package:medico_app/features/chat/services/chat_service.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// HomeScreen agora apenas recebe o currentUser e decide qual layout mostrar.
// Não precisa mais de aceder aos providers, evitando o erro.
class HomeScreen extends StatelessWidget {
  final AppUser currentUser;

  const HomeScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    if (currentUser.userType == 'medico') {
      return _DoctorHomeScreen(currentUser: currentUser);
    } else {
      return _PatientHomeScreenWithTabs(currentUser: currentUser);
    }
  }
}

//-------------------------------------------------------------------
// NAVEGAÇÃO E TELAS DO PACIENTE
//-------------------------------------------------------------------

class _PatientHomeScreenWithTabs extends StatefulWidget {
  final AppUser currentUser;

  const _PatientHomeScreenWithTabs({required this.currentUser});

  @override
  State<_PatientHomeScreenWithTabs> createState() =>
      _PatientHomeScreenWithTabsState();
}

class _PatientHomeScreenWithTabsState extends State<_PatientHomeScreenWithTabs> {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      _PatientHomeScreen(currentUser: widget.currentUser),
      const ListaConversasScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(_selectedIndex == 0 ? 'Encontrar Médico' : 'Minhas Conversas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthController>().handleLogout();
            },
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Médicos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Conversas',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _PatientHomeScreen extends StatelessWidget {
  final AppUser currentUser;

  const _PatientHomeScreen({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Acede diretamente ao Firestore para evitar problemas de contexto com o Provider
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bem-vindo, ${currentUser.nome}!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  // CORREÇÃO: Cria uma nova instância do ChatService diretamente.
                  // Isto resolve o erro "Provider not found" de forma definitiva.
                  final chatService = ChatService();
                  await chatService.getOrCreateConversation(
                    currentUser.uid,
                    medico.uid,
                  );

                  if (!context.mounted) return;
                  context.go('/chat', extra: medico);
                },
                child: const Text('Iniciar Conversa'),
              ),
            ],
          ),
        );
      },
    );
  }
}

//-------------------------------------------------------------------
// NAVEGAÇÃO E TELAS DO MÉDICO
//-------------------------------------------------------------------

class _DoctorHomeScreen extends StatefulWidget {
  final AppUser currentUser;

  const _DoctorHomeScreen({required this.currentUser});

  @override
  State<_DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<_DoctorHomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      _DoctorDashboard(currentUser: widget.currentUser),
      const ListaConversasScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Painel Principal' : 'Conversas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthController>().handleLogout();
            },
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize_outlined),
            label: 'Painel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Conversas',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _DoctorDashboard extends StatelessWidget {
  final AppUser currentUser;

  const _DoctorDashboard({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bem-vindo(a),',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                        Text(
                          currentUser.nome,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ações Rápidas',
            style:
                theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
