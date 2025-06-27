import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.read<AuthController>();
    final user = authController.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tela Principal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () {
              // Faz o logout e o GoRouter cuidará do redirecionamento para o login
              authController.handleLogout();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bem-vindo(a), ${user?.nome ?? 'Usuário'}!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('Tipo de usuário: ${user?.userType ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Status: ${user?.status ?? 'N/A'}'),
              const SizedBox(height: 32),

              // Botões condicionais baseados no tipo de usuário
              if (user?.userType == 'paciente')
                ElevatedButton(
                  onPressed: () {
                    // Navega para a tela de lista de usuários (médicos) para iniciar um chat
                    // Certifique-se de que a rota '/lista-usuarios' existe no seu GoRouter
                    context.go('/lista-usuarios');
                  },
                  child: const Text('Iniciar Conversa com Médico'),
                ),
              if (user?.userType == 'medico')
                ElevatedButton(
                  onPressed: () {
                    // Médicos podem ser direcionados a uma lista de suas conversas
                    // Certifique-se de que a rota '/conversas' existe no seu GoRouter
                    context.go('/conversas');
                  },
                  child: const Text('Ver Minhas Conversas'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}