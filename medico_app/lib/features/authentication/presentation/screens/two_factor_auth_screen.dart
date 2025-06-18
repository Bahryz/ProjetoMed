import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';

class TwoFactorAuthScreen extends StatelessWidget {
  final AppUser user; 
  const TwoFactorAuthScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final authController = context.read<AuthController>();
    const primaryColor = Color(0xFFB89453);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificação de Segurança'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove o botão de voltar
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.security_outlined, size: 80, color: primaryColor),
              const SizedBox(height: 20),
              const Text(
                'Confirme sua identidade',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Para proteger sua conta, por favor, selecione um método de verificação.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              
              ElevatedButton.icon(
                icon: const Icon(Icons.sms_outlined),
                label: const Text('Receber código por SMS'),
                onPressed: () {
                  // CORREÇÃO: Usando 'telefone' em vez de 'phone'
                  if (user.telefone != null && user.telefone!.isNotEmpty) {
                    authController.handlePhoneSignIn(context, user.telefone!);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nenhum telefone cadastrado para este usuário.'))
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              
              OutlinedButton.icon(
                icon: const Icon(Icons.email_outlined),
                label: const Text('Receber link de acesso por E-mail'),
                onPressed: () {
                  // CORREÇÃO: Chamando o método agora existente no controller
                  authController.handleEmailLinkSignIn(context, user.email!);
                },
                 style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  // CORREÇÃO: Deprecated 'withOpacity' removido
                  side: BorderSide(color: primaryColor.withAlpha(128)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 40),
              TextButton(
                onPressed: () {
                  // CORREÇÃO: Chamando handleLogout() e navegando para a tela de login
                  authController.handleLogout();
                  context.go('/login');
                }, 
                child: const Text('Cancelar e sair', style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
        ),
      ),
    );
  }
}