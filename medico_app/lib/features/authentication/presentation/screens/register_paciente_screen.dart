// 1. IMPORTE OS PACOTES NECESSÁRIOS
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import '../controllers/auth_controller.dart';

class RegisterPacienteScreen extends StatefulWidget {
  const RegisterPacienteScreen({super.key});

  @override
  State<RegisterPacienteScreen> createState() => _RegisterPacienteScreenState();
}

class _RegisterPacienteScreenState extends State<RegisterPacienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  // 2. CRIE UMA VARIÁVEL PARA GUARDAR O NÚMERO COMPLETO
  String? _fullPhoneNumber;

  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 3. AJUSTE A FUNÇÃO DE SUBMISSÃO PARA INCLUIR O TELEFONE
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authController = context.read<AuthController>();
    final appUser = AppUser(
      uid: '',
      nome: _nomeController.text.trim(),
      email: _emailController.text.trim(),
      cpf: _cpfFormatter.getUnmaskedText(),
      // Adiciona o telefone ao objeto AppUser
      telefone: _fullPhoneNumber,
      userType: 'paciente',
      crm: null,
    );

    await authController.handleRegister(
      appUser,
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de Paciente')),
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
                    if (!value!.contains('@') || !value.contains('.'))
                      return 'Email inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 4. ADICIONE O WIDGET DO CAMPO DE TELEFONE
                IntlPhoneField(
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(),
                    ),
                  ),
                  initialCountryCode: 'BR', // Define o Brasil como país inicial
                  onChanged: (phone) {
                    // A cada alteração, salva o número completo (código do país + número)
                    _fullPhoneNumber = phone.completeNumber;
                  },
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _cpfController,
                  decoration: const InputDecoration(labelText: 'CPF'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [_cpfFormatter],
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Campo obrigatório';
                    if (_cpfFormatter.getUnmaskedText().length != 11) {
                      return 'CPF inválido';
                    }
                    return null;
                  },
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