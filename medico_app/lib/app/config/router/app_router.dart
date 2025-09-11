// medico_app/lib/app/config/router/app_router.dart

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
import 'package:medico_app/features/documentos/presentation/screens/documentos_screen.dart';
import 'package:medico_app/features/authentication/presentation/screens/image_viewer_screen.dart';
import 'package:medico_app/features/medico/presentation/screens/add_conteudo_educativo_screen.dart'; // A tela de listagem
import 'package:medico_app/features/medico/presentation/screens/create_conteudo_educativo_screen.dart'; // A nova tela de criação
import 'package:medico_app/features/medico/presentation/screens/agenda_screen.dart';
import 'package:medico_app/features/medico/presentation/screens/conteudo_educativo.dart' as conteudo;
import 'package:medico_app/features/medico/presentation/screens/feedbacks_screen.dart';
import 'package:medico_app/features/paciente/presentation/screens/meus_agentamentos.dart';
import 'package:medico_app/features/paciente/presentation/screens/solicitar_agentamento_screen.dart';
import 'package:medico_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:medico_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:medico_app/features/paciente/presentation/screens/paciente_conteudo_educativo_screen.dart';


class AppRouter {
  final AuthController authController;

  AppRouter(this.authController);

  late final GoRouter router = GoRouter(
    refreshListenable: authController,
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          final user = Provider.of<AuthController>(context, listen: false).user;
          if (user == null) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          return HomeScreen(currentUser: user);
        },
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/documentos',
          builder: (context, state) => const DocumentosScreen()),
      GoRoute(
        path: '/image-viewer',
        builder: (context, state) {
          final imageUrl = state.extra as String?;
          if (imageUrl == null) {
            return const Scaffold(body: Center(child: Text("URL da imagem não fornecida.")));
          }
          return ImageViewerScreen(imageUrl: imageUrl);
        },
      ),
      GoRoute(
          path: '/register-paciente',
          builder: (context, state) => const RegisterPacienteScreen()),
      GoRoute(
          path: '/register-medico',
          builder: (context, state) => const RegisterMedicoScreen()),
      GoRoute(
          path: '/verify-email',
          builder: (context, state) => const VerifyEmailScreen()),
      GoRoute(
          path: '/pending-approval',
          builder: (context, state) => const PendingApprovalScreen()),
      GoRoute(
          path: '/conversas',
          builder: (context, state) => const ListaConversasScreen()),
      GoRoute(
          path: '/lista-usuarios',
          builder: (context, state) => const ListaUsuariosScreen()),
      GoRoute(
          path: '/configuracoes',
          builder: (context, state) => const SettingsScreen()),
      
      // ROTA DE PERFIL ADICIONADA
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      
      // ROTAS DA ÁREA MÉDICA
      GoRoute(
          path: '/agenda',
          builder: (context, state) => const AgendaScreen()),
      GoRoute(
          path: '/conteudo-educativo',
          builder: (context, state) => const conteudo.ConteudoEducativoScreen()),
      GoRoute(
        path: '/add-conteudo-educativo',
        builder: (context, state) => const AddConteudoEducativoScreen(),
      ),
      GoRoute(
        path: '/create-conteudo-educativo',
        builder: (context, state) => const CreateConteudoEducativoScreen(),
      ),
      GoRoute(
          path: '/feedbacks',
          builder: (context, state) => const FeedbacksScreen()),

      // ROTAS DA ÁREA DO PACIENTE
      GoRoute(
        path: '/solicitar-agendamento',
        builder: (context, state) => const SolicitarAgendamentoScreen(),
      ),
      GoRoute(
        path: '/meus-agendamentos',
        builder: (context, state) => const MeusAgendamentosScreen(),
      ),
      GoRoute(
        path: '/paciente-conteudo-educativo',
        builder: (context, state) => const PacienteConteudoEducativoScreen(),
      ),

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
      final unauthenticatedRoutes = [
        '/login',
        '/register-paciente',
        '/register-medico'
      ];
      final isGoingToUnauthenticatedRoute =
          unauthenticatedRoutes.contains(state.matchedLocation);
      final currentLocation = state.matchedLocation;

      switch (status) {
        case AuthStatus.unauthenticated:
          return isGoingToUnauthenticatedRoute ? null : '/login';
        case AuthStatus.emailNotVerified:
          return currentLocation == '/verify-email' ? null : '/verify-email';
        case AuthStatus.pendingApproval:
          return currentLocation == '/pending-approval'
              ? null
              : '/pending-approval';
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