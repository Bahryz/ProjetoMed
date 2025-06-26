import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:medico_app/features/authentication/presentation/screens/image_viewer_screen.dart';
import 'package:medico_app/features/chat/services/chat_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';



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

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _enviarMensagem() {
    if (_messageController.text.trim().isNotEmpty) {
      _chatService.enviarMensagem(
        widget.conversaId,
        widget.remetenteId,
        _messageController.text,
      );
      _messageController.clear();
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _enviarImagem() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final Uint8List fileBytes = await pickedFile.readAsBytes();
        final String fileName = pickedFile.name;

        await _chatService.enviarArquivo(
            widget.conversaId, widget.remetenteId, fileBytes, fileName, 'imagem');
      }
    } catch (e) {
      _showErrorSnackBar('Não foi possível enviar a imagem.');
    }
  }

  void _enviarArquivo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        final Uint8List fileBytes = file.bytes!;
        final String fileName = file.name;
        final String? extension = file.extension?.toLowerCase();

        final imageExtensions = ['jpg', 'jpeg', 'png'];
        String tipo = 'arquivo';
        if (extension != null && imageExtensions.contains(extension)) {
          tipo = 'imagem';
        }

        await _chatService.enviarArquivo(
            widget.conversaId, widget.remetenteId, fileBytes, fileName, tipo);
      }
    } catch (e) {
      _showErrorSnackBar('Não foi possível enviar o arquivo.');
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
                if (snapshot.hasError) {
                  return const Center(child: Text('Erro ao carregar mensagens.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final mensagens = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) {
                    final mensagemDoc = mensagens[index];
                    final mensagemData =
                        mensagemDoc.data() as Map<String, dynamic>;
                    final bool isMe =
                        mensagemData['remetenteId'] == widget.remetenteId;

                    if (!isMe && mensagemData['statusLeitura'] != 'lido') {
                      _chatService.marcarComoLida(
                          widget.conversaId, mensagemDoc.id);
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

  Widget _buildMessageBubble(Map<String, dynamic> mensagem, bool isMe) {
    final status = mensagem['statusLeitura'];
    final tipo = mensagem['tipo'] ?? 'texto';
    final conteudo = mensagem['conteudo'] ?? '';
    final nomeArquivo = mensagem['nomeArquivo'] as String?;

    Widget conteudoWidget;
    switch (tipo) {
      case 'imagem':
        conteudoWidget = GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImageViewerScreen(imageUrl: conteudo),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.6,
                maxHeight: MediaQuery.of(context).size.width * 0.8,
              ),
              // ATUALIZAÇÃO: Usando CachedNetworkImage para a miniatura
              child: CachedNetworkImage(
                imageUrl: conteudo,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              ),
            ),
          ),
        );
        break;
      case 'arquivo':
        conteudoWidget = InkWell(
          onTap: () async {
            final uri = Uri.tryParse(conteudo);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              _showErrorSnackBar('Não foi possível abrir o arquivo.');
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file,
                  color: isMe ? Colors.black54 : Colors.black87),
              const SizedBox(width: 8),
              Flexible(
                  child: Text(nomeArquivo ?? 'Arquivo',
                      style:
                          const TextStyle(decoration: TextDecoration.underline))),
            ],
          ),
        );
        break;
      default:
        conteudoWidget = Text(conteudo);
    }

    Icon? statusIcon;
    if (isMe) {
      switch (status) {
        case 'lido':
          statusIcon =
              const Icon(Icons.done_all, color: Colors.blue, size: 16);
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
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            conteudoWidget,
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
