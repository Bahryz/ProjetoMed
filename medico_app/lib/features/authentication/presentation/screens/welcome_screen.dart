import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFB89453);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Espaçador para empurrar o conteúdo para o centro/parte superior
              const Spacer(flex: 2),

              // LOGO E TÍTULO
              const Icon(
                Icons.shield_moon_outlined, // Ícone elegante que remete a cuidado e proteção
                size: 80,
                color: primaryColor,
              ),
              const SizedBox(height: 20),
              const Text(
                'Seu Cuidado, Nossa Prioridade',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Acesse uma nova experiência em gestão de saúde.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),

              // Espaçador para separar o conteúdo do botão
              const Spacer(flex: 3),

              // BOTÃO DE ACESSO
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => context.go('/login'),
                child: const Text(
                  'Acessar minha conta',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 40), // Espaço na parte inferior
            ],
          ),
        ),
      ),
    );
  }
}
