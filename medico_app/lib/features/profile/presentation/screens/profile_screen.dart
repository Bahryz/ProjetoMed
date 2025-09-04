import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';

// Paleta de cores do app
const Color primaryColor = Color(0xFFB89453);
const Color accentColor = Color(0xFF4A4A4A);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Acessa o usuário logado através do AuthController
    final AppUser? user = context.watch<AuthController>().user;

    // Lida com o caso em que o usuário não está disponível (carregando, etc.)
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meu Perfil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Meu Perfil',
          style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: accentColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProfileHeader(user),
          const SizedBox(height: 24),
          _buildInfoCard(user),
        ],
      ),
    );
  }

  // Cabeçalho do perfil com nome e tipo de usuário
  Widget _buildProfileHeader(AppUser user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: primaryColor.withOpacity(0.1),
          child: const Icon(Icons.person, size: 60, color: primaryColor),
        ),
        const SizedBox(height: 16),
        Text(
          user.nome,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.userType == 'medico' ? 'Médico(a)' : 'Paciente',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Card com as informações detalhadas do usuário
  Widget _buildInfoCard(AppUser user) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações Pessoais',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildInfoTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email ?? 'Não informado',
            ),
            _buildInfoTile(
              icon: Icons.phone_outlined,
              label: 'Telefone',
              value: user.telefone ?? 'Não informado',
            ),
            // Exibe CRM para médico ou CPF para paciente
            if (user.userType == 'medico')
              _buildInfoTile(
                icon: Icons.medical_services_outlined,
                label: 'CRM',
                value: user.crm ?? 'Não informado',
              )
            else if (user.userType == 'paciente')
              _buildInfoTile(
                icon: Icons.badge_outlined,
                label: 'CPF',
                value: user.cpf ?? 'Não informado',
              ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para cada linha de informação
  Widget _buildInfoTile({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[500]),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}