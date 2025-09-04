import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:medico_app/features/paciente/data/services/paciente_services.dart';
import 'package:provider/provider.dart';

const Color primaryColor = Color(0xFFB89453);

class SolicitarAgendamentoScreen extends StatefulWidget {
  const SolicitarAgendamentoScreen({super.key});

  @override
  State<SolicitarAgendamentoScreen> createState() =>
      _SolicitarAgendamentoScreenState();
}

class _SolicitarAgendamentoScreenState
    extends State<SolicitarAgendamentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedTime != null) {
      setState(() => _isLoading = true);
      
      final paciente = context.read<AuthController>().user;
      if (paciente == null) {
        // Tratar caso o usuário não esteja logado
        setState(() => _isLoading = false);
        return;
      }

      final dataFinal = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      try {
        await PacienteService().solicitarAgendamento(
          paciente: paciente,
          data: dataFinal,
          motivo: _motivoController.text.trim(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitação de agendamento enviada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar solicitação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar Agendamento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Seletor de Data
              ListTile(
                leading: const Icon(Icons.calendar_today, color: primaryColor),
                title: const Text('Data da Consulta'),
                subtitle: Text(_selectedDate == null
                    ? 'Selecione uma data'
                    : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
                onTap: () => _selectDate(context),
              ),
              const Divider(),
              // Seletor de Hora
              ListTile(
                leading: const Icon(Icons.access_time, color: primaryColor),
                title: const Text('Hora da Consulta'),
                subtitle: Text(_selectedTime == null
                    ? 'Selecione um horário'
                    : _selectedTime!.format(context)),
                onTap: () => _selectTime(context),
              ),
              const SizedBox(height: 24),
              // Motivo da consulta
              TextFormField(
                controller: _motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo da Consulta',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) => (value?.isEmpty ?? true)
                    ? 'Por favor, informe o motivo da consulta'
                    : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                label: const Text('Enviar Solicitação', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}