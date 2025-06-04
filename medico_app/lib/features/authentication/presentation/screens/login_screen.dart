import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usamos o Consumer para ouvir as mudanças no AuthController
    final authController = context.watch<AuthController>();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Projeto X',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      (value?.isEmpty ?? true) ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                  validator: (value) =>
                      (value?.isEmpty ?? true) ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 24),
                // Exibe o indicador de progresso se estiver carregando
                authController.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<AuthController>().handleSignIn(
                                  _emailController.text.trim(),
                                  _passwordController.text.trim(),
                                );
                          }
                        },
                        child: const Text('Entrar'),
                      ),
                const SizedBox(height: 8),
                // Exibe mensagem de erro se houver
                if (authController.errorMessage != null)
                  Text(
                    authController.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go('/register-paciente'),
                  child: const Text('Não tem cadastro? Cadastre-se como paciente.'),
                ),
                TextButton(
                  onPressed: () => context.go('/register-medico'),
                  child: const Text('É médico? Cadastre-se aqui.'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}