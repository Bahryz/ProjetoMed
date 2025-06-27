import 'package:flutter/material.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/chat/services/chat_service.dart';
import 'package:medico_app/features/chat/services/user_service.dart';
import 'package:medico_app/features/chat/presentation/screens/detalhes_chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';

class ListaUsuariosScreen extends StatelessWidget {
  const ListaUsuariosScreen({super.key});

  static const Color primaryColor = Color(0xFFB89453);
  static const Color accentColor = Color(0xFF4A4A4A);
  static const Color backgroundColor = Color(0xFFF7F7F7);

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final chatService = ChatService();
    final authController = context.read<AuthController>();
    final currentUserId = authController.user?.uid;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text("Erro: Usuário não autenticado.")),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Iniciar Nova Conversa',
          style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1.0,
        iconTheme: const IconThemeData(color: accentColor),
      ),
      body: StreamBuilder<List<AppUser>>(
        // A chamada agora funcionará porque o método existe em UserService
        stream: userService.getMedicosStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint("Erro no StreamBuilder: ${snapshot.error}");
            return const Center(child: Text('Erro ao carregar os médicos.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum médico disponível no momento.'));
          }

          final medicos = snapshot.data!;

          return ListView.builder(
            itemCount: medicos.length,
            itemBuilder: (context, index) {
              final medico = medicos[index];
              // Não exibe o próprio usuário na lista (caso um médico esteja vendo a lista)
              if (medico.uid == currentUserId) return const SizedBox.shrink(); 
              
              final String inicial = medico.nome.isNotEmpty ? medico.nome[0].toUpperCase() : 'M';

              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryColor.withAlpha(51),
                      child: Text(inicial, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ),
                    title: Text("Dr(a). ${medico.nome}", style: const TextStyle(fontWeight: FontWeight.bold, color: accentColor)),
                    subtitle: Text(medico.crm ?? "Médico", style: TextStyle(color: Colors.grey[600])),
                    onTap: () async {
                      try {
                        // O nome do método no ChatService também foi padronizado
                        final conversaId = await chatService.getOrCreateConversation(currentUserId, medico.uid);
                        
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetalhesChatScreen(
                                conversaId: conversaId,
                                destinatarioNome: "Dr(a). ${medico.nome}",
                                remetenteId: currentUserId,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Erro ao iniciar conversa: $e"))
                          );
                        }
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 72, endIndent: 16),
                ],
              );
            },
          );
        },
      ),
    );
  }
}