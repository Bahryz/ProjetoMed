// medico_app/lib/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Busca o usuário logado através do AuthController
    final AppUser? user = context.watch<AuthController>().user;
    final theme = Theme.of(context);

    if (user == null) {
      // Se por algum motivo o usuário não for encontrado, mostra um erro.
      return Scaffold(
        appBar: AppBar(title: const Text('Meu Perfil')),
        body: const Center(
          child: Text('Usuário não encontrado. Por favor, faça login novamente.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Avatar do Perfil
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.surface,
              child: Icon(
                Icons.person,
                size: 50,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            // Nome e Tipo de Usuário
            Text(
              user.nome,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user.userType == 'medico' ? 'Médico(a)' : 'Paciente',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[400]),
            ),
            const SizedBox(height: 40),
            // Card de Informações Pessoais
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informações Pessoais',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context,
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email ?? 'Não informado',
                    ),
                    _buildInfoRow(
                      context,
                      icon: Icons.phone_outlined,
                      label: 'Telefone',
                      value: user.telefone ?? 'Não informado',
                    ),
                    // Mostra o CRM para médicos e CPF para pacientes
                    if (user.userType == 'medico')
                      _buildInfoRow(
                        context,
                        icon: Icons.medical_services_outlined,
                        label: 'CRM',
                        value: user.crm ?? 'Não informado',
                      )
                    else
                      _buildInfoRow(
                        context,
                        icon: Icons.badge_outlined,
                        label: 'CPF',
                        value: user.cpf ?? 'Não informado',
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para criar as linhas de informação
  Widget _buildInfoRow(BuildContext context, {required IconData icon, required String label, required String value}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
              ),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}