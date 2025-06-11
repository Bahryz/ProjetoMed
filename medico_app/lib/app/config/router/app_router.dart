import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // Certifique-se de que o provider está importado
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:medico_app/features/authentication/presentation/screens/login_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/register_medico_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/register_paciente_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/verify_email_screen.dart';

// Exemplo de HomeScreen
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tela Principal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // CORRIGIDO: O método correto é handleLogout
              context.read<AuthController>().handleLogout();
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Bem-vindo!'),
      ),
    );
  }
}

class AppRouter {
  final AuthController authController;

  AppRouter(this.authController);

  late final GoRouter router = GoRouter(
    refreshListenable: authController,
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register-medico', builder: (context, state) => const RegisterMedicoScreen()),
      GoRoute(path: '/register-paciente', builder: (context, state) => const RegisterPacienteScreen()),
      GoRoute(path: '/verify-email', builder: (context, state) => const VerifyEmailScreen()),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    ],
    redirect: (context, state) {
      // CORRIGIDO: usa 'authStatus' em vez de 'status'
      final authStatus = authController.authStatus;
      final user = authController.user;

      final isAuthenticating = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register-medico' ||
          state.matchedLocation == '/register-paciente' ||
          state.matchedLocation == '/verify-email';

      if (authStatus == AuthStatus.unauthenticated) {
        return isAuthenticating ? null : '/login';
      }

      if (authStatus == AuthStatus.authenticated) {
        if (user != null && !user.emailVerified) {
          return state.matchedLocation == '/verify-email' ? null : '/verify-email';
        }
        if (isAuthenticating) {
          return '/';
        }
      }

      return null;
    },
  );
}