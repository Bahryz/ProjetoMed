import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:medico_app/app/config/router/app_router.dart';
import 'firebase_options.dart'; 


void main() async {
  // Garante que os bindings do Flutter foram inicializados
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // Inicializa o Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Seu App Médico',
      // Você vai configurar o router de verdade no Passo 6
      routerConfig: AppRouter.router, 
    );
  }
}