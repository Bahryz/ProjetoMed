import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:medico_app/app/config/router/app_router.dart';
import 'package:medico_app/app/config/theme/app_theme.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/authentication/data/repositories/auth_repository.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:medico_app/features/chat/services/user_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

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
        ProxyProvider<AuthController, GoRouter>(
          update: (context, authController, previous) =>
              AppRouter(authController).router,
        ),
      ],
      child: Builder(
        builder: (context) {
          final router = Provider.of<GoRouter>(context);
          return MaterialApp.router(
            title: 'Med App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.mainTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}

