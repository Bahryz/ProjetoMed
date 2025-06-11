import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        final userProfile = authController.appUser;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tela Principal'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Sair',
                onPressed: () {
                  context.read<AuthController>().handleLogout();
                },
              ),
            ],
          ),
          body: Center(
            child: userProfile == null
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Bem-vindo(a), ${userProfile.nome ?? 'Usuário'}!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      if (userProfile.email != null && userProfile.email!.isNotEmpty)
                        Text(
                          'Seu e-mail: ${userProfile.email}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                       if (userProfile.telefone != null && userProfile.telefone!.isNotEmpty)
                        Text(
                          'Telefone: ${userProfile.telefone}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      if (userProfile.crm != null)
                        Text(
                          'CRM: ${userProfile.crm}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      if (userProfile.cpf != null)
                        Text(
                          'CPF: ${userProfile.cpf}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}