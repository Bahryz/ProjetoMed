import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
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
  String? _fullPhoneNumber;
  String? _selectedUF;

  final _phoneFormatter = MaskTextInputFormatter(
      mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});

  final List<String> _estados = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS',
    'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC',
    'SP', 'SE', 'TO'
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _crmController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = context.read<AuthController>();
    final crmCompleto = '${_crmController.text.trim()}/$_selectedUF';

    final appUser = AppUser(
      uid: '',
      nome: _nomeController.text.trim(),
      email: _emailController.text.trim(),
      crm: crmCompleto,
      telefone: _fullPhoneNumber,
      userType: 'medico',
      cpf: null,
    );

    await authController.handleRegister(appUser, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    // 1. DEFINIÇÃO DA NOVA COR PRIMÁRIA
    const primaryColor = Color(0xFFB89453);

    const inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Criar Conta de Médico'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 2. APLICAÇÃO DA NOVA COR NO ÍCONE
              const Icon(Icons.medical_services_outlined, size: 60, color: primaryColor),
              const SizedBox(height: 10),
              const Text('Acesso Médico', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const Text('Preencha seus dados profissionais', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 30),
              Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nomeController,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Nome Completo',
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator: (v) => (v?.isEmpty ?? true) ? 'Campo obrigatório' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v?.isEmpty ?? true) return 'Campo obrigatório';
                            if (!v!.contains('@') || !v.contains('.')) return 'Email inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _crmController,
                                decoration: inputDecoration.copyWith(
                                  labelText: 'Número CRM',
                                  prefixIcon: const Icon(Icons.badge_outlined),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) => (v?.isEmpty ?? true) ? 'Obrigatório' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                decoration: inputDecoration.copyWith(labelText: 'UF'),
                                value: _selectedUF,
                                items: _estados.map((String estado) {
                                  return DropdownMenuItem<String>(
                                    value: estado,
                                    child: Text(estado),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedUF = newValue;
                                  });
                                },
                                validator: (v) => (v == null) ? 'Selecione' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        IntlPhoneField(
                          // 3. REMOÇÃO DO CONTADOR "0/11"
                          decoration: inputDecoration.copyWith(
                            labelText: 'Telefone',
                            counterText: "", // Deixa o texto do contador vazio
                          ),
                          languageCode: "pt_BR",
                          initialCountryCode: 'BR',
                          inputFormatters: [_phoneFormatter],
                          onChanged: (phone) {
                            _fullPhoneNumber = phone.completeNumber;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                          obscureText: true,
                           validator: (v) {
                            if (v?.isEmpty ?? true) return 'Campo obrigatório';
                            if (v!.length < 6) return 'Senha deve ter no mínimo 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Confirmar Senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                          obscureText: true,
                          validator: (v) {
                             if (v?.isEmpty ?? true) return 'Campo obrigatório';
                            if (v != _passwordController.text) return 'As senhas não coincidem';
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        authController.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  // 4. APLICAÇÃO DA NOVA COR NO BOTÃO
                                  backgroundColor: primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _submit,
                                child: const Text('Cadastrar', style: TextStyle(fontSize: 16, color: Colors.white)),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Já tem uma conta?"),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    // 5. APLICAÇÃO DA NOVA COR NO LINK
                    child: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                  ),
                ],
              ),
              if (authController.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    authController.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
