import 'package:flutter/material.dart';
import 'package:medico_app/features/admin/presentation/admin_service.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:provider/provider.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  final AdminService _adminService = AdminService();
  late Future<List<AppUser>> _pendingMedicosFuture;

  @override
  void initState() {
    super.initState();
    _loadPendingMedicos();
  }

  void _loadPendingMedicos() {
    setState(() {
      _pendingMedicosFuture = _adminService.getPendingMedicos();
    });
  }

  Future<void> _updateStatus(String uid, String status) async {
    try {
      await _adminService.updateUserStatus(uid, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Médico ${status == 'aprovado' ? 'aprovado' : 'rejeitado'} com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadPendingMedicos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF005A8D);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aprovações Pendentes'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthController>().handleLogout();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<AppUser>>(
        future: _pendingMedicosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar dados: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _loadPendingMedicos(),
              child: ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'Nenhum médico pendente de aprovação.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final medicos = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              _loadPendingMedicos();
            },
            child: ListView.builder(
              itemCount: medicos.length,
              itemBuilder: (context, index) {
                final medico = medicos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medico.nome,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Email: ${medico.email ?? "Não informado"}'),
                        const SizedBox(height: 4),
                        Text('CRM: ${medico.crm ?? 'Não informado'}'),
                        const SizedBox(height: 4),
                        Text('Telefone: ${medico.telefone ?? 'Não informado'}'),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _updateStatus(medico.uid, 'rejeitado'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Rejeitar'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _updateStatus(medico.uid, 'aprovado'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Aprovar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
