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

  // Paleta de cores profissional baseada na tela de login
  static const Color primaryColor = Color(0xFFB89453);
  static const Color accentColor = Color(0xFF4A4A4A);
  static const Color backgroundColor = Color(0xFFF7F7F7);
  static const Color senderBubbleColor = primaryColor;
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
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

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

      await _chatService.enviarArquivo(widget.conversaId, widget.remetenteId, fileBytes, fileName, tipo);
    } catch (e) {
      _showErrorSnackBar('Não foi possível enviar o arquivo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(widget.destinatarioNome, style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
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
                if (snapshot.hasError) return const Center(child: Text('Erro ao carregar mensagens.'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final mensagens = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(12.0),
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) {
                    final mensagemDoc = mensagens[index];
                    final mensagemData = mensagemDoc.data() as Map<String, dynamic>;
                    final bool isMe = mensagemData['remetenteId'] == widget.remetenteId;

                    if (!isMe && (mensagemData['statusLeitura'] ?? 'enviado') != 'lido') {
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

  Widget _buildMessageBubble(Map<String, dynamic> mensagem, bool isMe) {
    final tipo = mensagem['tipo'] ?? 'texto';
    final conteudo = mensagem['conteudo'] ?? '';
    final nomeArquivo = mensagem['nomeArquivo'] as String?;

    final bubbleColor = isMe ? senderBubbleColor : receiverBubbleColor;
    final textColor = isMe ? Colors.white : accentColor;
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
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ImageViewerScreen(imageUrl: conteudo))),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: CachedNetworkImage(
              imageUrl: conteudo,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(height: 200, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
              errorWidget: (context, url, error) => Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[200],
                child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.error, color: Colors.red), SizedBox(height: 8), Text("Falha ao carregar", style: TextStyle(color: Colors.red))]),
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
              Icon(Icons.insert_drive_file, color: isMe ? Colors.white70 : Colors.black54),
              const SizedBox(width: 8),
              Flexible(child: Text(nomeArquivo ?? 'Arquivo', style: TextStyle(color: textColor, decoration: TextDecoration.underline))),
            ],
          ),
        );
        break;
      default:
        conteudoWidget = Text(conteudo, style: TextStyle(color: textColor, fontSize: 16));
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: tipo == 'imagem' ? EdgeInsets.zero : const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(color: bubbleColor, borderRadius: borderRadius, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: conteudoWidget,
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -5))]),
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
                      ListTile(leading: const Icon(Icons.photo_library), title: const Text('Enviar Imagem'), onTap: () {Navigator.of(context).pop(); _enviarMidia(daGaleria: true);}),
                      ListTile(leading: const Icon(Icons.insert_drive_file), title: const Text('Enviar Documento'), onTap: () {Navigator.of(context).pop(); _enviarMidia(daGaleria: false);}),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
