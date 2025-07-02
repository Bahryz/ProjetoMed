import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:medico_app/features/chat/presentation/screens/home_screen.dart';

// Importe todas as telas que serão usadas nas rotas
import 'package:medico_app/features/authentication/presentation/screens/login_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/register_paciente_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/register_medico_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/verify_email_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/pending_approval_screen.dart';
import 'package:medico_app/features/chat/presentation/screens/lista_usuarios_screen.dart';
import 'package:medico_app/features/chat/presentation/screens/detalhes_chat_screen.dart';
import 'package:medico_app/features/chat/presentation/screens/lista_conversas_screen.dart';
import 'package:medico_app/features/settings/presentation/screens/settings_screen.dart';

class AppRouter {
  final AuthController authController;

  AppRouter(this.authController);

  late final GoRouter router = GoRouter(
    refreshListenable: authController,
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register-paciente',
        builder: (context, state) => const RegisterPacienteScreen(),
      ),
      GoRoute(
        path: '/register-medico',
        builder: (context, state) => const RegisterMedicoScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/pending-approval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: '/lista-usuarios',
        builder: (context, state) => const ListaUsuariosScreen(),
      ),
      GoRoute(
        path: '/conversas',
        builder: (context, state) => const ListaUsuariosScreen(),  
      ),
      GoRoute(
        path: '/conversas',
        name: 'conversas',
        builder: (context, state) => const ListaConversasScreen(),
      ),
      GoRoute(
        path: '/configuracoes',
        name: 'configuracoes',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      // A linha abaixo pode variar dependendo de como você expõe seu controller.
      // Se estiver usando Riverpod, pode ser: final authController = ref.read(authControllerProvider.notifier);
      final status = authController.authStatus; 

      final unauthenticatedRoutes = ['/login', '/register-paciente', '/register-medico'];
      final isGoingToUnauthenticatedRoute = unauthenticatedRoutes.contains(state.matchedLocation);

      // Pega a rota atual do usuário
      final currentLocation = state.matchedLocation;

      switch (status) {
        case AuthStatus.unauthenticated:
          // Se não está logado, só pode acessar rotas de não-autenticado.
          // Caso contrário, vai para o login.
          return isGoingToUnauthenticatedRoute ? null : '/login';

        case AuthStatus.emailNotVerified:
          // Se o e-mail não foi verificado, força o usuário a ir para a tela de verificação.
          return currentLocation == '/verify-email' ? null : '/verify-email';

        case AuthStatus.pendingApproval:
          // Se o cadastro do médico está pendente, força a ida para a tela de aviso.
          return currentLocation == '/pending-approval' ? null : '/pending-approval';

        case AuthStatus.authenticated:
          // Se o usuário está autenticado e tenta acessar o login/registro,
          // ou a rota raiz, redireciona para a tela principal de conversas.
          if (isGoingToUnauthenticatedRoute || currentLocation == '/') {
            return '/conversas';
          }
          // Caso contrário, permite a navegação.
          return null;
      }
    },
  );
}