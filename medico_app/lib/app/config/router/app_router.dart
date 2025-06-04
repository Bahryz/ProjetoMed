import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../features/authentication/presentation/screens/login_screen.dart';
import '../../../features/authentication/presentation/screens/register_medico_screen.dart';
import '../../../features/authentication/presentation/screens/register_paciente_screen.dart';
import '../../../features/authentication/data/repositories/auth_repository.dart';

// Tela simples para representar a home após o login
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.read<AuthRepository>().signOut(),
          child: const Text('Sair'),
        ),
      ),
    );
  }
}


class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
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
    // Lógica de redirecionamento
    redirect: (context, state) {
      final authRepository = context.read<AuthRepository>();
      final isAuth = authRepository.currentUser != null;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register-medico' ||
          state.matchedLocation == '/register-paciente';

      // Se não estiver logado e tentando acessar algo que não seja a tela de login/registro, redireciona para /login
      if (!isAuth && !isLoggingIn) {
        return '/login';
      }
      // Se estiver logado e na tela de login/registro, redireciona para /home
      if (isAuth && isLoggingIn) {
        return '/home';
      }
      return null; // Nenhuma ação de redirecionamento necessária
    },
    // Atualiza as rotas quando o estado de autenticação muda
    refreshListenable: GoRouterRefreshStream(
      context.watch<AuthRepository>().authStateChanges(),
    ),
  );
}

// Classe auxiliar para o refreshListenable do GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final Stream<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}