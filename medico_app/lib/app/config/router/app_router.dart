import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:medico_app/features/authentication/presentation/screens/login_screen.dart';
import 'package:medico_app/features/home/home_screen.dart';
// Importe suas outras telas aqui
// import 'package:medico_app/features/authentication/presentation/screens/verify_email_screen.dart';
// import 'package:medico_app/features/authentication/presentation/screens/pending_approval_screen.dart';

class AppRouter {
  final AuthController authController;

  AppRouter(this.authController);

  late final GoRouter router = GoRouter(
    refreshListenable: authController,
    initialLocation: '/login', // Pode ser ajustado conforme a necessidade
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
       // Exemplo de rotas que você precisaria criar
      /*
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/pending-approval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      */
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
          // Se autenticado, não deve acessar as telas de login/registro
          return isGoingToUnauthenticatedRoute ? '/' : null;
      }
    },
  );
}