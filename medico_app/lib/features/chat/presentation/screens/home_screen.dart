// HomeScreen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Mude o import
import 'package:go_router/go_router.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
// Remova o import do user_service, não é mais necessário aqui

// Muda de ConsumerWidget para StatelessWidget
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Acessa o AuthController via context.watch
    final userType = context.watch<AuthController>().user?.userType;

    if (userType == 'paciente') {
      return const _PatientHomeScreen();
    } else {
      return const _DoctorDashboard();
    }
  }
}

// Muda de ConsumerWidget para StatelessWidget
class _DoctorDashboard extends StatelessWidget {
  const _DoctorDashboard();

  @override
  Widget build(BuildContext context) {
    // Acessa o AuthController via context.watch
    final authController = context.watch<AuthController>();
    final user = authController.user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Painel do Médico',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            // Usa context.read para chamar uma função
            onPressed: () async {
              await context.read<AuthController>().handleLogout();
            },
            tooltip: 'Sair',
          ),
        ],
      ),
      // ... O resto do seu widget _DoctorDashboard não precisa mudar
      // (SingleChildScrollView, Card, GridView, etc.)
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blueGrey,
                      child: Icon(Icons.person, size: 30, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bem-vindo(a),',
                            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                          ),
                          Text(
                            user?.nome ?? 'Doutor(a)',
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  context,
                  icon: Icons.people_alt_outlined,
                  label: 'Ver Pacientes',
                  color: Colors.blue.shade700,
                  onTap: () => context.go('/lista-usuarios'),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.settings_outlined,
                  label: 'Configurações',
                  color: Colors.grey.shade700,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tela de configurações a ser implementada.')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // O método _buildActionCard não precisa de alterações
  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 1,
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// Muda de ConsumerWidget para StatelessWidget
class _PatientHomeScreen extends StatelessWidget {
  const _PatientHomeScreen();

  @override
  Widget build(BuildContext context) {
    // Acessa a stream do médico via context.watch
    // A stream agora nos dá um AppUser? diretamente.
    final AppUser? doctor = context.watch<AppUser?>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fale com o Médico'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            // Usa context.read para chamar a função
            onPressed: () async {
              await context.read<AuthController>().handleLogout();
            },
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // Como o StreamProvider já lida com os estados,
          // podemos checar diretamente o dado.
          child: doctor == null
              ? const Text('Nenhum médico disponível no momento.')
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.blue),
                    const SizedBox(height: 24),
                    Text(
                      'Pronto para começar?',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Clique no botão abaixo para iniciar uma conversa segura com o seu médico.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Iniciar Conversa com Médico'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () {
                        context.go('/chat', extra: doctor);
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}