// lib/features/chat/presentation/screens/detalhes_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medico_app/features/chat/services/chat_service.dart'; // Ajuste o import
// Importe outros pacotes necessários, como image_picker, file_picker, audioplayers

class DetalhesChatScreen extends StatefulWidget {
  final String conversaId;
  final String destinatarioNome;
  final String remetenteId;

  const DetalhesChatScreen({
    super.key,
    required this.conversaId,
    required this.destinatarioNome,
    required this.remetenteId,
  });

  @override
  State<DetalhesChatScreen> createState() => _DetalhesChatScreenState();
}

class _DetalhesChatScreenState extends State<DetalhesChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();

  void _enviarMensagem() {
    _chatService.enviarMensagem(
      widget.conversaId,
      widget.remetenteId,
      _messageController.text,
    );
    _messageController.clear();
    // Animar para o final da lista
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.destinatarioNome)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMensagensStream(widget.conversaId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Erro ao carregar mensagens.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final mensagens = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Mostra do mais novo para o mais antigo
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) {
                    final mensagem = mensagens[index].data() as Map<String, dynamic>;
                    final bool isMe = mensagem['remetenteId'] == widget.remetenteId;

                    // TODO: Marcar a mensagem como lida se não for minha
                    if (!isMe && mensagem['statusLeitura'] != 'lido') {
                      _chatService.marcarComoLida(widget.conversaId, mensagens[index].id);
                    }

                    // Aqui você constrói o widget da mensagem (texto, imagem, audio)
                    return _buildMessageBubble(mensagem, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> mensagem, bool isMe) {
    final status = mensagem['statusLeitura'];
    Icon? statusIcon;
    if (isMe) {
      if (status == 'lido') {
        statusIcon = const Icon(Icons.done_all, color: Colors.blue, size: 16);
      } else if (status == 'entregue') {
        statusIcon = const Icon(Icons.done_all, color: Colors.grey, size: 16);
      } else {
        statusIcon = const Icon(Icons.done, color: Colors.grey, size: 16);
      }
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
             // TODO: Retornar widget de acordo com o `mensagem['tipo']`
            Text(mensagem['conteudo']),
            if (isMe) ...[
              const SizedBox(height: 4),
              statusIcon!,
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Digite uma mensagem...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                 prefixIcon: IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {
                    // TODO: Lógica para anexar arquivos/fotos
                  },
                ),
              ),
              onSubmitted: (value) => _enviarMensagem(),
            ),
          ),
          const SizedBox(width: 8.0),
          FloatingActionButton(
            mini: true,
            onPressed: _enviarMensagem,
            child: const Icon(Icons.send),
          )
        ],
      ),
    );
  }
}