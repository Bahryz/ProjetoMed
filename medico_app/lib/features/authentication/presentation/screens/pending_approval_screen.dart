import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  // Paleta de cores profissional
  static const Color primaryColor = Color(0xFFB89453);
  static const Color accentColor = Color(0xFF4A4A4A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                size: 80,
                color: primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Cadastro em Análise',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Seu perfil de médico foi enviado e está aguardando aprovação da nossa equipe. Você será notificado assim que o processo for concluído.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              TextButton(
                onPressed: () {
                  context.read<AuthController>().handleLogout();
                },
                child: const Text(
                  'Sair',
                  style: TextStyle(color: primaryColor, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
