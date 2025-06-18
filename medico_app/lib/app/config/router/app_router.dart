import 'package:go_router/go_router.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:medico_app/features/authentication/presentation/screens/register_medico_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/register_paciente_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/verify_email_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/chat_screen.dart';
// 1. IMPORTAÇÃO CORRIGIDA: Aponta para a nova tela de login
import 'package:medico_app/features/authentication/presentation/screens/login_screen.dart'; 
import 'package:medico_app/features/authentication/presentation/screens/otp_verify_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/welcome_screen.dart';

class AppRouter {
  final AuthController authController;

  AppRouter(this.authController);

  late final GoRouter router = GoRouter(
    refreshListenable: authController,
      
    routes: [
      GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
      // 2. ROTA ATUALIZADA para usar a LoginScreen correta
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register-medico', builder: (context, state) => const RegisterMedicoScreen()),
      GoRoute(path: '/register-paciente', builder: (context, state) => const RegisterPacienteScreen()),
      GoRoute(path: '/verify-email', builder: (context, state) => const VerifyEmailScreen()),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) {
          final verificationId = state.extra as String;
          return OtpVerifyScreen(verificationId: verificationId);
        },
      ),
      
      GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
    ],

    redirect: (context, state) {
      final authStatus = authController.authStatus;
      final user = authController.user;

       final publicRoutes = [
        '/', 
        '/login',
        '/register-medico',
        '/register-paciente',
        '/verify-otp'
      ];

      final isGoingToPublicRoute = publicRoutes.contains(state.matchedLocation);

      if (authStatus == AuthStatus.authenticated) {
        if (user != null && user.email != null && !user.emailVerified) {
          return state.matchedLocation == '/verify-email' ? null : '/verify-email';
        }
        
    
        if (isGoingToPublicRoute) {
          return '/chat';
        }
      } 
      else if (authStatus == AuthStatus.unauthenticated) {
    
        return isGoingToPublicRoute || state.matchedLocation == '/verify-email'
          ? null
          : '/';
      }

      return null;
    },
  );
}
