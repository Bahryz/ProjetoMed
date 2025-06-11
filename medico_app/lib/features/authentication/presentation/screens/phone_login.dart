import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _phoneFormatter = MaskTextInputFormatter(
    mask: '+55 (##) #####-####', 
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy
  );

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Entrar com Celular')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Insira seu número de celular para continuar'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                inputFormatters: [_phoneFormatter],
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Celular'),
                validator: (value) {
                  if (_phoneFormatter.getUnmaskedText().length < 11) {
                    return 'Número de celular inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              authController.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final phoneNumber = '+55${_phoneFormatter.getUnmaskedText()}';
                          context.read<AuthController>().handlePhoneSignIn(context, phoneNumber);
                        }
                      },
                      child: const Text('Enviar Código SMS'),
                    ),
              if (authController.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  authController.errorMessage!,
                  style: const TextStyle(color: Colors.red),
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