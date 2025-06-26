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

  // REFINEMENT 1: Consolidating file sending logic into one method.
  void _enviarMidia({bool daGaleria = false}) async {
    try {
      final XFile? pickedFile;
      Uint8List? fileBytes;
      String? fileName;

      if (daGaleria) {
        pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (pickedFile == null) return;
        fileBytes = await pickedFile.readAsBytes();
        fileName = pickedFile.name;
      } else {
        final result = await FilePicker.platform.pickFiles(type: FileType.any);
        if (result == null || result.files.single.bytes == null) return;
        fileBytes = result.files.single.bytes!;
        fileName = result.files.single.name;
      }

      final extension = fileName.split('.').last.toLowerCase();
      final imageExtensions = ['jpg', 'jpeg', 'png', 'gif'];
      final tipo = imageExtensions.contains(extension) ? 'imagem' : 'arquivo';

      await _chatService.enviarArquivo(
          widget.conversaId, widget.remetenteId, fileBytes, fileName, tipo);

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

                    if (!isMe && (mensagemData['statusLeitura'] ?? 'enviado') != 'lido') {
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
    final tipo = mensagem['tipo'] ?? 'texto';
    final conteudo = mensagem['conteudo'] ?? '';
    final nomeArquivo = mensagem['nomeArquivo'] as String?;

    Widget conteudoWidget;
    switch (tipo) {
      case 'imagem':
        // REFINEMENT 2: Making the image widget more robust.
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
              child: CachedNetworkImage(
                imageUrl: conteudo,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) {
                  print("Erro ao carregar imagem: $error"); // For debugging
                  return Container(
                    color: Colors.grey[200],
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 40),
                        SizedBox(height: 4),
                        Text("Falha", style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  );
                },
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
                  color: isMe ? Colors.white70 : Colors.black54),
              const SizedBox(width: 8),
              Flexible(
                  child: Text(nomeArquivo ?? 'Arquivo',
                      style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
                          decoration: TextDecoration.underline))),
            ],
          ),
        );
        break;
      default:
        conteudoWidget = Text(conteudo, style: TextStyle(color: isMe ? Colors.white : Colors.black));
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: conteudoWidget, // Simplified this part
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
                                title: const Text('Enviar Imagem da Galeria'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _enviarMidia(daGaleria: true);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.insert_drive_file),
                                title: const Text('Enviar Documento'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _enviarMidia(daGaleria: false);
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
