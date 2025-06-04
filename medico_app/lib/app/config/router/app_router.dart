// lib/app/config/router/app_router.dart
import 'dart:async'; // GoRouterRefreshStream pode precisar
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
// Removi o import do firebase_auth.dart daqui, pois o AuthController o gerencia
// import 'package:firebase_auth/firebase_auth.dart';

import '../../../features/authentication/presentation/controllers/auth_controller.dart';
import '../../../features/authentication/presentation/screens/login_screen.dart';
import '../../../features/authentication/presentation/screens/register_medico_screen.dart';
import '../../../features/authentication/presentation/screens/register_paciente_screen.dart';

// Tela de Home simples (mova para seu próprio arquivo em features/home/presentation/screens)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthController>().handleSignOut(),
          ),
        ],
      ),
      body: const Center(child: Text('Bem-vindo!')),
    );
  }
}

class AppRouter {
  final AuthController authController;

  AppRouter(this.authController);

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: authController, // Ouve o AuthController
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register-medico',
        builder: (context, state) => const RegisterMedicoScreen(),
      ),
      GoRoute(
        path: '/register-paciente',
        builder: (context, state) => const RegisterPacienteScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    redirect: (context, state) {
      final authStatus = authController.status;
      final bool loggedIn = authStatus == AuthStatus.authenticated;
      
      final String location = state.uri.toString();

      // NOME DA VARIÁVEL CORRIGIDO AQUI:
      final isOnAuthRoutes = location.startsWith('/login') ||
          location.startsWith('/register-medico') ||
          location.startsWith('/register-paciente');

      // Se não estiver logado e tentando acessar rota protegida
      if (!loggedIn && !isOnAuthRoutes) { // Agora usa o nome correto
        return '/login';
      }

      // Se estiver logado e tentando acessar rota de autenticação
      if (loggedIn && isOnAuthRoutes) { // Agora usa o nome correto
        return '/home';
      }
      return null; // Nenhuma ação de redirecionamento necessária
    },
  );
}