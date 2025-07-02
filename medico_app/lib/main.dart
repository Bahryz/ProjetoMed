import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:medico_app/app/config/router/app_router.dart';
import 'package:medico_app/features/authentication/data/repositories/auth_repository.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(
          create: (_) => AuthRepository(),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (context) => AuthController(context.read<AuthRepository>()),
        ),
        ProxyProvider<AuthController, GoRouter>(
          update: (context, authController, previous) => AppRouter(authController).router,
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
