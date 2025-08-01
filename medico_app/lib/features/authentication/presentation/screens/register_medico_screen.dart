import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:provider/provider.dart';
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

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  double _passwordStrength = 0;

  final List<String> _estados = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS',
    'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC',
    'SP', 'SE', 'TO'
  ];

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _crmController.dispose();
    _passwordController.removeListener(_updatePasswordStrength);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    String password = _passwordController.text;
    setState(() {
      _passwordStrength = _checkPasswordStrength(password);
    });
  }

  double _checkPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.25;
    return strength > 1.0 ? 1.0 : strength;
  }

  Color _getStrengthColor(double strength) {
    if (strength < 0.5) return Colors.red;
    if (strength < 0.75) return Colors.orange;
    return Colors.green;
  }

  String _getStrengthText(double strength) {
    if (strength == 0) return '';
    if (strength < 0.5) return 'Fraca';
    if (strength < 0.75) return 'Média';
    if (strength < 1.0) return 'Forte';
    return 'Muito Forte';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sem conexão com a internet. Por favor, verifique sua rede.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

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
      status: 'pendente',
    );

    await authController.handleRegister(appUser, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final isLoading = authController.isLoading;

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.medical_services_outlined, size: 60, color: primaryColor),
              const SizedBox(height: 10),
              const Text('Conta Profissional', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const Text('Informe seus dados para o cadastro', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
                          enabled: !isLoading,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Nome Completo',
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator: (v) => (v?.isEmpty ?? true) ? 'Campo obrigatório' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          enabled: !isLoading,
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
                                enabled: !isLoading,
                                decoration: inputDecoration.copyWith(
                                  labelText: 'Número CRM',
                                  prefixIcon: const Icon(Icons.badge_outlined),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Obrigatório';
                                  }
                                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                    return 'Apenas números';
                                  }
                                  if (value.length > 8) {
                                    return 'Máx. 8 dígitos';
                                  }
                                  return null;
                                },
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
                                onChanged: isLoading ? null : (newValue) {
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
                          enabled: !isLoading,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Telefone',
                            counterText: "",
                          ),
                          languageCode: "pt_BR",
                          initialCountryCode: 'BR',
                          onChanged: (phone) {
                            _fullPhoneNumber = phone.completeNumber;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !isLoading,
                          obscureText: _isPasswordObscured,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  _isPasswordObscured = !_isPasswordObscured;
                                });
                              },
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Campo obrigatório';
                            }
                            if (_checkPasswordStrength(v) < 1.0) {
                              return 'A senha deve conter maiúscula, minúscula, número e símbolo.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        if (_passwordController.text.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: _passwordStrength,
                                backgroundColor: Colors.grey[300],
                                minHeight: 6,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    _getStrengthColor(_passwordStrength)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getStrengthText(_passwordStrength),
                                style: TextStyle(
                                  color: _getStrengthColor(_passwordStrength),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          enabled: !isLoading,
                          obscureText: _isConfirmPasswordObscured,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Confirmar Senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_isConfirmPasswordObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordObscured =
                                      !_isConfirmPasswordObscured;
                                });
                              },
                            ),
                          ),
                          validator: (v) {
                            if (v?.isEmpty ?? true) return 'Campo obrigatório';
                            if (v != _passwordController.text)
                              return 'As senhas não coincidem';
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: primaryColor.withOpacity(0.5),
                          ),
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Cadastrar', style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: isLoading ? null : () => context.go('/login'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: primaryColor.withAlpha(77)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios_new, size: 16, color: primaryColor.withAlpha(204)),
                    const SizedBox(width: 8),
                    const Text(
                      'Voltar para o Login',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
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
