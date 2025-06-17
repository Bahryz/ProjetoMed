// lib/features/chat/presentation/screens/detalhes_chat_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:medico_app/features/chat/services/chat_service.dart';

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
    if (_messageController.text.trim().isNotEmpty) {
      _chatService.enviarMensagem(
        widget.conversaId,
        widget.remetenteId,
        _messageController.text,
      );
      _messageController.clear();
      // Animar para o final da lista
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _enviarImagem() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      await _chatService.enviarArquivo(widget.conversaId, widget.remetenteId, file, 'imagem');
    }
  }

  void _enviarArquivo() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = File(result.files.single.path!);
      await _chatService.enviarArquivo(widget.conversaId, widget.remetenteId, file, 'arquivo');
    }
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
                if (snapshot.hasError) return const Center(child: Text('Erro ao carregar mensagens.'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final mensagens = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) {
                    final mensagemDoc = mensagens[index];
                    final mensagemData = mensagemDoc.data() as Map<String, dynamic>;
                    final bool isMe = mensagemData['remetenteId'] == widget.remetenteId;

                    if (!isMe && mensagemData['statusLeitura'] != 'lido') {
                      _chatService.marcarComoLida(widget.conversaId, mensagemDoc.id);
                    }
                    return _buildMessageBubble(mensagemData, isMe);
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

  // =======================================================================
  // MÉTODO CORRIGIDO E COMPLETO
  // =======================================================================
  Widget _buildMessageBubble(Map<String, dynamic> mensagem, bool isMe) {
    final status = mensagem['statusLeitura'];
    final tipo = mensagem['tipo'] ?? 'texto';
    final conteudo = mensagem['conteudo'] ?? '';

    // --- A VARIÁVEL AGORA É DECLARADA E USADA CORRETAMENTE ---
    Widget conteudoWidget;
    switch (tipo) {
      case 'imagem':
        conteudoWidget = Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(conteudo, fit: BoxFit.cover),
          ),
        );
        break;
      case 'arquivo':
        conteudoWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, color: isMe ? Colors.black54 : Colors.black87),
            const SizedBox(width: 8),
            const Text('Arquivo'),
          ],
        );
        break;
      default: // texto
        conteudoWidget = Text(conteudo);
    }
    
    Icon? statusIcon;
    if (isMe) {
      switch (status) {
        case 'lido':
          statusIcon = const Icon(Icons.done_all, color: Colors.blue, size: 16);
          break;
        case 'entregue':
          statusIcon = const Icon(Icons.done_all, color: Colors.grey, size: 16);
          break;
        default:
          statusIcon = const Icon(Icons.done, color: Colors.grey, size: 16);
      }
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            conteudoWidget, // <- Uso correto da variável
            if (isMe && statusIcon != null) ...[
              const SizedBox(height: 4),
              statusIcon,
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
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => SafeArea(
                          child: Wrap(
                            children: <Widget>[
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Enviar Imagem'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _enviarImagem();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.insert_drive_file),
                                title: const Text('Enviar Documento'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _enviarArquivo();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Digite uma mensagem...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) => _enviarMensagem(),
                    ),
                  ),
                ],
              ),
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