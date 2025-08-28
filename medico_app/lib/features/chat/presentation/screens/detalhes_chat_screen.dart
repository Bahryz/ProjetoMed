// bahryz/projetomed/ProjetoMed-6502db256f60032b63be3b6019c0ea07dd298519/medico_app/lib/features/chat/presentation/screens/detalhes_chat_screen.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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

  static const Color primaryColor = Color(0xFFB89453);
  static const Color accentColor = Color(0xFF4A4A4A);
  static const Color backgroundColor = Color(0xFFECE5DD);
  static const Color senderBubbleColor = Color(0xFFE7FFDB);
  static const Color receiverBubbleColor = Colors.white;

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
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

  // --- IMPLEMENTAÇÃO CORRIGIDA ---
  // Função para enviar imagens ou documentos
  Future<void> _enviarArquivo(String tipo) async {
    try {
      if (kIsWeb) {
        // Lógica para Web
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: tipo == 'imagem' ? FileType.image : FileType.any,
        );
        if (result != null && result.files.single.bytes != null) {
          final fileBytes = result.files.single.bytes!;
          final fileName = result.files.single.name;
          String finalTipo;
          if (tipo == 'imagem') {
            finalTipo = 'imagem';
          } else {
            final extension = fileName.split('.').last.toLowerCase();
            if (extension == 'pdf') {
              finalTipo = 'pdf';
            } else {
              finalTipo = 'outro';
            }
          }
          await _chatService.enviarArquivo(
              widget.conversaId, widget.remetenteId, fileBytes, fileName, tipo);
        }
      } else {
        // Lógica para Mobile (iOS/Android)
        if (tipo == 'imagem') {
          final picker = ImagePicker();
          final pickedFile = await picker.pickImage(source: ImageSource.gallery);
          if (pickedFile != null) {
            final fileBytes = await pickedFile.readAsBytes();
            await _chatService.enviarArquivo(widget.conversaId,
                widget.remetenteId, fileBytes, pickedFile.name, 'imagem');
          }
        } else {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf', 'doc', 'docx'],
          );
          if (result != null && result.files.single.path != null) {
             final file = result.files.single;
             // CORREÇÃO: Lê os bytes diretamente do caminho do arquivo
             final fileBytes = await File(file.path!).readAsBytes();
             String finalTipo;
             final extension = file.name.split('.').last.toLowerCase();
             if (extension == 'pdf') {
               finalTipo = 'pdf';
              } else {
               finalTipo = 'outro';
              }
            await _chatService.enviarArquivo(
                widget.conversaId, widget.remetenteId, fileBytes, file.name, 'arquivo');
          }
        }
      }
    } catch (e) {
      _showErrorSnackBar('Ocorreu um erro ao selecionar o arquivo: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.destinatarioNome,
            style:
                const TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1.0,
        iconTheme: const IconThemeData(color: accentColor),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMensagensStream(widget.conversaId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorWidget(snapshot.error.toString());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyChatWidget();
                }

                final mensagens = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(12.0),
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) {
                    final mensagemDoc = mensagens[index];
                    final data = mensagemDoc.data();
                    final mensagemData =
                        (data != null && data is Map<String, dynamic>)
                            ? data
                            : <String, dynamic>{};

                    final bool isMe =
                        mensagemData['remetenteId'] == widget.remetenteId;

                    if (!isMe &&
                        (mensagemData['statusLeitura'] ?? 'enviado') != 'lido') {
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

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade300)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            const Text(
              'Ocorreu um erro ao carregar o chat:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error, // Exibe o erro real do Firebase
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 16),
            const Text(
              "Verifique se as regras de segurança do Firestore foram publicadas corretamente.",
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChatWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          const Text(
            'Nenhuma mensagem aqui',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Envie uma mensagem para iniciar a conversa.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> mensagem, bool isMe) {
    final tipo = mensagem['tipo'] ?? 'texto';
    final conteudo = mensagem['conteudo'] ?? '[Mensagem vazia]';
    final nomeArquivo = mensagem['nomeArquivo'] as String?;

    final bubbleColor = isMe ? senderBubbleColor : receiverBubbleColor;
    final textColor = isMe ? Colors.black : accentColor;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isMe ? 20 : 0),
      bottomRight: Radius.circular(isMe ? 0 : 20),
    );

    Widget conteudoWidget;
    switch (tipo) {
      case 'imagem':
        conteudoWidget = GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ImageViewerScreen(imageUrl: conteudo))),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: CachedNetworkImage(
              imageUrl: conteudo,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator())),
              errorWidget: (context, url, error) => Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[200],
                child: const Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(height: 8),
                  Text("Falha ao carregar", style: TextStyle(color: Colors.red))
                ]),
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
                  color: isMe ? Colors.black54 : Colors.black54),
              const SizedBox(width: 8),
              Flexible(
                  child: Text(nomeArquivo ?? 'Arquivo',
                      style: TextStyle(
                          color: textColor,
                          decoration: TextDecoration.underline))),
            ],
          ),
        );
        break;
      default:
        conteudoWidget =
            Text(conteudo, style: TextStyle(color: textColor, fontSize: 16));
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: tipo == 'imagem'
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2))
            ]),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: conteudoWidget,
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -5))
      ]),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: accentColor),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Wrap(
                    children: <Widget>[
                      ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Enviar Imagem'),
                          onTap: () {
                            Navigator.of(context).pop();
                            _enviarArquivo('imagem');
                          }),
                      ListTile(
                          leading: const Icon(Icons.insert_drive_file),
                          title: const Text('Enviar Documento'),
                          onTap: () {
                            Navigator.of(context).pop();
                            _enviarArquivo('arquivo');
                          }),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Digite uma mensagem...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                ),
                onSubmitted: (value) => _enviarMensagem(),
              ),
            ),
            const SizedBox(width: 8.0),
            FloatingActionButton(
              mini: true,
              onPressed: _enviarMensagem,
              backgroundColor: primaryColor,
              elevation: 0,
              child: const Icon(Icons.send, color: Colors.white),
            )
          ],
        ),
      ),
    );
  }
}