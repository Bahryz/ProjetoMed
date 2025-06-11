import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:medico_app/features/authentication/presentation/screens/login_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/register_medico_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/register_paciente_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/verify_email_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/home_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/phone_login_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/otp_verify_screen.dart';

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
      GoRoute(path: '/phone-login', builder: (context, state) => const PhoneLoginScreen()),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) {
          final verificationId = state.extra as String;
          return OtpVerifyScreen(verificationId: verificationId);
        },
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    ],
    redirect: (context, state) {
      final authStatus = authController.authStatus;
      final user = authController.user;

      final onAuthScreens = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register-medico' ||
          state.matchedLocation == '/register-paciente' ||
          state.matchedLocation == '/verify-email' ||
          state.matchedLocation == '/phone-login' ||
          state.matchedLocation == '/verify-otp';

      if (authStatus == AuthStatus.unauthenticated) {
        return onAuthScreens ? null : '/login';
      }

      if (authStatus == AuthStatus.authenticated) {
        if (user != null && user.email != null && !user.emailVerified) {
          return state.matchedLocation == '/verify-email' ? null : '/verify-email';
        }
        if (onAuthScreens) {
          return '/';
        }
      }

      return null;
    },
  );
}