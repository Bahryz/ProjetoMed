import 'package:flutter/material.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/chat/services/chat_service.dart';
import 'package:medico_app/features/chat/services/user_service.dart';
import 'package:medico_app/features/chat/presentation/screens/detalhes_chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';

class ListaUsuariosScreen extends StatelessWidget {
  const ListaUsuariosScreen({super.key});

  // Paleta de cores profissional
  static const Color primaryColor = Color(0xFFB89453);
  static const Color accentColor = Color(0xFF4A4A4A);
  static const Color backgroundColor = Color(0xFFF7F7F7);

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final chatService = ChatService();
    // Usar 'read' é mais apropriado aqui, pois não precisamos reconstruir o widget se o auth mudar.
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
        // Usando o stream para buscar apenas médicos, conforme sua lógica
        stream: userService.getMedicosStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint("Erro no StreamBuilder: ${snapshot.error}");
            return const Center(child: Text('Erro ao carregar usuários.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum médico encontrado.'));
          }

          final medicos = snapshot.data!;

          return ListView.builder(
            itemCount: medicos.length,
            itemBuilder: (context, index) {
              final medico = medicos[index];
              // Não mostrar o próprio usuário na lista
              // CORREÇÃO 1: 'id' foi trocado por 'uid'
              if (medico.uid == currentUserId) return const SizedBox.shrink();
              
              final String inicial = medico.nome?.isNotEmpty == true ? medico.nome![0].toUpperCase() : 'M';

              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      // CORREÇÃO 2: 'withOpacity' foi trocado por 'withAlpha'
                      backgroundColor: primaryColor.withAlpha(51), // 20% de opacidade
                      child: Text(inicial, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(medico.nome ?? 'Nome não disponível', style: const TextStyle(fontWeight: FontWeight.bold, color: accentColor)),
                    subtitle: Text("Médico", style: TextStyle(color: Colors.grey[600])),
                    onTap: () async {
                      try {
                        debugPrint("onTap iniciado para o médico: ${medico.nome}");
                        
                        debugPrint("Tentando criar ou obter a conversa...");
                        // CORREÇÃO 3: 'getOrCreateConversa' foi corrigido para 'getOrCreateConversation' e 'medico.id' para 'medico.uid'
                        final conversaId = await chatService.getOrCreateConversation(currentUserId, medico.uid);
                        debugPrint("Conversa ID obtida com sucesso: $conversaId");

                        debugPrint("Navegando para a tela de detalhes do chat...");
                        
                        if (context.mounted) {
                          // Usando Navigator.push para permitir voltar à lista
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetalhesChatScreen(
                                conversaId: conversaId,
                                destinatarioNome: medico.nome ?? 'Médico',
                                remetenteId: currentUserId,
                              ),
                            ),
                          );
                          debugPrint("Navegação concluída.");
                        }
                      } catch (e) {
                        debugPrint("!!!!!!!!!! ERRO NO ONTAP !!!!!!!!!!");
                        debugPrint(e.toString());
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
