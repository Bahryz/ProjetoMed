import 'package:flutter/material.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:provider/provider.dart';
import 'package:medico_app/app/config/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final userType = authController.user?.userType;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Conta'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Editar Perfil'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Implementar navegação para tela de edição de perfil
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Alterar Senha'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
               // TODO: Implementar navegação para tela de alteração de senha
            },
          ),

          // Exemplo de configuração que só aparece para médicos
          if (userType == 'medico') ...[
            const Divider(height: 32),
            _buildSectionHeader('Notificações (Médico)'),
            SwitchListTile(
              title: const Text('Novas solicitações de consulta'),
              value: true, // Placeholder
              onChanged: (value) {},
              secondary: const Icon(Icons.notifications_active_outlined, color: AppTheme.primaryColor),
              activeColor: AppTheme.primaryColor,
            ),
          ],
          
          const SizedBox(height: 40),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Sair da Conta', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await context.read<AuthController>().handleLogout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 16.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          fontSize: 14,
        ),
      ),
    );
  }
}
