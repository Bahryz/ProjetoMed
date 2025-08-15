import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:medico_app/features/authentication/presentation/screens/login_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/pending_approval_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/register_medico_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/register_paciente_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/verify_email_screen.dart';
import 'package:medico_app/features/chat/presentation/screens/detalhes_chat_screen.dart';
import 'package:medico_app/features/chat/presentation/screens/home_screen.dart';
import 'package:medico_app/features/chat/presentation/screens/lista_conversas_screen.dart';
import 'package:medico_app/features/chat/presentation/screens/lista_usuarios_screen.dart';
import 'package:medico_app/features/settings/presentation/screens/settings_screen.dart';

class AppRouter {
  final AuthController authController;

  AppRouter(this.authController);

  late final GoRouter router = GoRouter(
    refreshListenable: authController,
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register-paciente', builder: (context, state) => const RegisterPacienteScreen()),
      GoRoute(path: '/register-medico', builder: (context, state) => const RegisterMedicoScreen()),
      GoRoute(path: '/verify-email', builder: (context, state) => const VerifyEmailScreen()),
      GoRoute(path: '/pending-approval', builder: (context, state) => const PendingApprovalScreen()),
      GoRoute(path: '/conversas', builder: (context, state) => const ListaConversasScreen()),
      GoRoute(path: '/lista-usuarios', builder: (context, state) => const ListaUsuariosScreen()),
      GoRoute(path: '/configuracoes', builder: (context, state) => const SettingsScreen()),
      
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final currentUser = authController.user;
          final otherUser = state.extra as AppUser?;

          if (currentUser == null || otherUser == null) {
            return const ListaConversasScreen();
          }

          final uids = [currentUser.uid, otherUser.uid]..sort();
          final conversationId = uids.join('_');

          return DetalhesChatScreen(
            conversaId: conversationId,
            destinatarioNome: otherUser.nome,
            remetenteId: currentUser.uid,
          );
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final status = authController.authStatus;
      final unauthenticatedRoutes = ['/login', '/register-paciente', '/register-medico'];
      final isGoingToUnauthenticatedRoute = unauthenticatedRoutes.contains(state.matchedLocation);
      final currentLocation = state.matchedLocation;

      switch (status) {
        case AuthStatus.unauthenticated:
          return isGoingToUnauthenticatedRoute ? null : '/login';
        case AuthStatus.emailNotVerified:
          return currentLocation == '/verify-email' ? null : '/verify-email';
        case AuthStatus.pendingApproval:
          return currentLocation == '/pending-approval' ? null : '/pending-approval';
        case AuthStatus.authenticated:
          if (isGoingToUnauthenticatedRoute) {
            return '/';
          }
          return null;
      }
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Erro')),
      body: Center(
        child: Text('A rota ${state.uri} não foi encontrada.'),
      ),
    ),
  );
}