import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:provider/provider.dart';

class TwoFactorAuthScreen extends StatelessWidget {
  const TwoFactorAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Usuário não encontrado.")));
    }
    
    const primaryColor = Color(0xFFB89453);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Autenticação de Fatores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authController.handleLogout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.security, size: 80, color: primaryColor),
            const SizedBox(height: 20),
            const Text(
              'Verificação Adicional',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Escolha um método para verificar sua identidade.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            
            if (user.telefone != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.sms),
                label: const Text('Enviar código via SMS'),
                onPressed: () {
                  authController.handlePhoneSignIn(context, user.telefone!);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            
            const SizedBox(height: 20),

            if (user.email != null)
              OutlinedButton.icon(
                icon: const Icon(Icons.email_outlined),
                label: const Text('Enviar link via Email'),
                onPressed: () async {
                  final success = await authController.handleEmailLinkSignIn(user.email!);
                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link de login enviado! Verifique seu e-mail.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(authController.errorMessage ?? 'Não foi possível enviar o e-mail.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: primaryColor.withAlpha(128)),
                  foregroundColor: primaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}