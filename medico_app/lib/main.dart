// Imports corrigidos
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medico_app/app/config/router/app_router.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/authentication/data/repositories/auth_repository.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:medico_app/features/chat/services/user_service.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Providers de autenticação
        Provider<AuthRepository>(
          create: (_) => AuthRepository(),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (context) => AuthController(context.read<AuthRepository>()),
        ),

        // Providers de serviços e dados
        Provider<UserService>(
          create: (_) => UserService(),
        ),
        StreamProvider<List<AppUser>>(
          create: (context) => context.read<UserService>().getPatientsStream(),
          initialData: const [],
        ),
        StreamProvider<AppUser?>(
          create: (context) => context.read<UserService>().getDoctorStream(),
          initialData: null,
        ),
        
        // Provider do roteador
        ProxyProvider<AuthController, GoRouter>(
          update: (context, authController, previous) =>
              AppRouter(authController).router,
        ),
      ],
      child: Builder(
        builder: (context) {
          final router = Provider.of<GoRouter>(context);
          return MaterialApp.router(
            title: 'Seu App Médico',
            debugShowCheckedModeBanner: false,
            routerConfig: router,
          );
        },
      ),
    );
  }
}