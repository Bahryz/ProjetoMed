import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String verificationId;
  const OtpVerifyScreen({super.key, required this.verificationId});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Verificar Código')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Insira o código de 6 dígitos recebido por SMS.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'Código SMS', counterText: ""),
            ),
            const SizedBox(height: 24),
            authController.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () {
                      if (_otpController.text.length == 6) {
                        context.read<AuthController>().handleOtpVerification(
                              widget.verificationId,
                              _otpController.text.trim(),
                            );
                      }
                    },
                    child: const Text('Verificar e Entrar'),
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
    );
  }
}