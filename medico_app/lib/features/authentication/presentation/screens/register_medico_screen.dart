import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import '../controllers/auth_controller.dart';

class RegisterMedicoScreen extends StatefulWidget {
  const RegisterMedicoScreen({super.key});

  @override
  State<RegisterMedicoScreen> createState() => _RegisterMedicoScreenState();
}

class _RegisterMedicoScreenState extends State<RegisterMedicoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _crmController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _crmController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 1. AJUSTE A FUNÇÃO DE SUBMISSÃO
  Future<void> _submit() async {
    // Apenas continua se o formulário for válido
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authController = context.read<AuthController>();
    final appUser = AppUser(
      // O uid será preenchido pelo repositório
      uid: '',
      nome: _nomeController.text.trim(),
      email: _emailController.text.trim(),
      crm: _crmController.text.trim(),
      userType: 'medico',
      cpf: null, // Médico não preenche CPF nesta tela
    );

    // Chama o método de registro. O AuthController cuidará de mostrar
    // o indicador de progresso e tratar os erros. O GoRouter cuidará do
    // redirecionamento em caso de sucesso.
    await authController.handleRegister(
      appUser,
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de Médico')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(labelText: 'Nome Completo'),
                  validator: (value) =>
                      (value?.isEmpty ?? true) ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Campo obrigatório';
                    if (!value!.contains('@') || !value.contains('.')) return 'Email inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _crmController,
                  decoration: const InputDecoration(labelText: 'CRM'),
                  validator: (value) =>
                      (value?.isEmpty ?? true) ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Campo obrigatório';
                    if (value!.length < 6) {
                      return 'Senha muito curta (mínimo 6 caracteres)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Confirmar Senha'),
                  obscureText: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Campo obrigatório';
                    if (value != _passwordController.text) {
                      return 'As senhas não coincidem';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                authController.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Cadastrar'),
                      ),
                if (authController.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    authController.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Já tem conta? Entrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}