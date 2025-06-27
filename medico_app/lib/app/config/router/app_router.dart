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
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final status = authController.authStatus;
      
      final unauthenticatedRoutes = ['/login', '/register-paciente', '/register-medico'];
      final isGoingToUnauthenticatedRoute = unauthenticatedRoutes.contains(state.matchedLocation);

      switch (status) {
        case AuthStatus.unauthenticated:
   
          return isGoingToUnauthenticatedRoute ? null : '/login';

        case AuthStatus.emailNotVerified:
           return state.matchedLocation == '/verify-email' ? null : '/verify-email';

        case AuthStatus.pendingApproval:
           return state.matchedLocation == '/pending-approval' ? null : '/pending-approval';

        case AuthStatus.authenticated:
           
          return isGoingToUnauthenticatedRoute ? '/' : null;
      }
    },
  );
}