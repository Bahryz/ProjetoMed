// lib/features/medico/presentation/widgets/add_edit_conteudo_form.dart

import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:medico_app/features/medico/data/models/conteudo_educativo_model.dart';
import 'package:medico_app/features/medico/data/services/conteudo_educativo_service.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:provider/provider.dart';

enum InputType { url, file }

class AddEditConteudoForm extends StatefulWidget {
  final ConteudoEducativo? conteudoParaEditar;
  final ScrollController scrollController;

  const AddEditConteudoForm({
    super.key,
    this.conteudoParaEditar,
    required this.scrollController,
  });

  @override
  State<AddEditConteudoForm> createState() => _AddEditConteudoFormState();
}

class _AddEditConteudoFormState extends State<AddEditConteudoForm> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _urlController = TextEditingController();
  final _tagController = TextEditingController();
  final _urlFocusNode = FocusNode();

  InputType _inputType = InputType.url;
  bool _isLoading = false;
  bool _isFetchingPreview = false;
  String? _previewImageUrl;
  PlatformFile? _pickedFile;
  PlatformFile? _pickedThumbnail;

  final List<String> _tags = [];
  final List<String> _tagsSugeridas = ['Artigo', 'Vídeo', 'PDF', 'Nutrição', 'Exercícios'];

  final _service = ConteudoEducativoService();

  bool get _isEditing => widget.conteudoParaEditar != null;

  @override
  void initState() {
    super.initState();
    _urlFocusNode.addListener(_onUrlFocusChange);
    if (_isEditing) {
      final c = widget.conteudoParaEditar!;
      _tituloController.text = c.titulo;
      _descricaoController.text = c.descricao;
      _tags.addAll(c.tags);
      _previewImageUrl = c.thumbnailUrl;
      if (c.url.contains('firebasestorage.googleapis.com')) {
        _inputType = InputType.file;
      } else {
        _inputType = InputType.url;
        _urlController.text = c.url;
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _urlController.dispose();
    _tagController.dispose();
    _urlFocusNode.removeListener(_onUrlFocusChange);
    _urlFocusNode.dispose();
    super.dispose();
  }

  void _onUrlFocusChange() {
    if (!_urlFocusNode.hasFocus) _fetchUrlPreview();
  }

  Future<void> _fetchUrlPreview() async {
    final url = _urlController.text.trim();
    if (url.isNotEmpty && Uri.tryParse(url)?.isAbsolute == true) {
      setState(() {
        _isFetchingPreview = true;
        _previewImageUrl = null;
      });
      try {
        final data = await MetadataFetch.extract(url);
        if (mounted) {
          setState(() {
            _previewImageUrl = data?.image;
            if (_tituloController.text.isEmpty) _tituloController.text = data?.title ?? '';
            if (_descricaoController.text.isEmpty) _descricaoController.text = data?.description ?? '';
          });
        }
      } catch (e) {
        debugPrint('Erro ao buscar preview da URL: $e');
      } finally {
        if (mounted) setState(() => _isFetchingPreview = false);
      }
    }
  }

  Future<void> _pickFile(bool isThumbnail) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: isThumbnail ? FileType.image : FileType.any,
      withData: true,
    );
    if (result != null) {
      setState(() {
        if (isThumbnail) {
          _pickedThumbnail = result.files.single;
        } else {
          _pickedFile = result.files.single;
          if (_tituloController.text.isEmpty) _tituloController.text = _pickedFile!.name;
        }
      });
    }
  }
  
  void _addTag(String tag) {
    final formattedTag = tag.trim();
    if (formattedTag.isNotEmpty && !_tags.contains(formattedTag)) {
      setState(() {
        _tags.add(formattedTag);
        _tagController.clear();
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _tags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os campos obrigatórios e adicione ao menos uma tag.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final medicoId = context.read<AuthController>().user?.uid;
    if (medicoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro de autenticação.')));
      setState(() => _isLoading = false);
      return;
    }

    try {
      String? thumbnailUrl;
      if (_pickedThumbnail != null) {
        thumbnailUrl = await _service.uploadFile(
          fileBytes: _pickedThumbnail!.bytes!,
          fileName: _pickedThumbnail!.name,
          medicoId: medicoId,
        );
      } else {
        thumbnailUrl = _previewImageUrl;
      }
      
      String finalUrl;
      if (_inputType == InputType.url) {
        finalUrl = _urlController.text.trim();
      } else {
        if (_pickedFile != null) {
          finalUrl = await _service.uploadFile(
            fileBytes: _pickedFile!.bytes!,
            fileName: _pickedFile!.name,
            medicoId: medicoId,
          );
        } else if (_isEditing) {
          finalUrl = widget.conteudoParaEditar!.url;
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecione um arquivo para o conteúdo.')));
           setState(() => _isLoading = false);
           return;
        }
      }

      if (_isEditing) {
        await _service.updateConteudo(
          id: widget.conteudoParaEditar!.id,
          titulo: _tituloController.text.trim(),
          descricao: _descricaoController.text.trim(),
          tags: _tags,
          url: finalUrl,
          thumbnailUrl: thumbnailUrl,
        );
      } else {
        await _service.addConteudo(
          titulo: _tituloController.text.trim(),
          descricao: _descricaoController.text.trim(),
          tags: _tags,
          url: finalUrl,
          thumbnailUrl: thumbnailUrl,
          medicoId: medicoId,
        );
      }

      if (mounted) Navigator.of(context).pop();

    } on FirebaseException catch (e) {
      // CATCH ESPECÍFICO E MAIS DETALHADO PARA ERROS DO FIREBASE
      if (mounted) {
        String friendlyMessage = 'Erro do Firebase: ${e.message} (Código: ${e.code})';
        if (e.code == 'permission-denied') {
          friendlyMessage = 'Permissão negada. Verifique as regras de segurança do Firestore.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e, s) {
      // CATCH GENÉRICO PARA OUTROS ERROS
      debugPrint('Erro ao publicar conteúdo: $e');
      debugPrint('Stack trace: $s');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ocorreu um erro inesperado: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  // O restante do seu código do Widget build e dos métodos auxiliares continua o mesmo...
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_isEditing ? 'Editar Conteúdo' : 'Novo Conteúdo', style: Theme.of(context).textTheme.headlineSmall),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
            ],
          ),
        ),
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildSectionTitle('Fonte do Conteúdo'),
                SegmentedButton<InputType>(
                  segments: const [
                    ButtonSegment(value: InputType.url, label: Text('Link'), icon: Icon(Icons.link)),
                    ButtonSegment(value: InputType.file, label: Text('Arquivo'), icon: Icon(Icons.upload_file)),
                  ],
                  selected: {_inputType},
                  onSelectionChanged: (s) => setState(() => _inputType = s.first),
                ),
                const SizedBox(height: 16),
                if (_inputType == InputType.url)
                  TextFormField(
                    controller: _urlController,
                    focusNode: _urlFocusNode,
                    decoration: const InputDecoration(labelText: 'URL do Conteúdo', hintText: 'Cole o link aqui'),
                    keyboardType: TextInputType.url,
                    validator: (v) => (v!.isEmpty || Uri.tryParse(v)?.isAbsolute != true) ? 'URL inválida' : null,
                  ),
                if (_inputType == InputType.file)
                  _buildFilePicker('Selecionar arquivo', _pickedFile?.name, () => _pickFile(false)),

                const SizedBox(height: 24),
                _buildSectionTitle('Detalhes do Conteúdo'),
                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descricaoController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  maxLines: 4,
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                ),
                
                const SizedBox(height: 24),
                _buildSectionTitle('Capa (Thumbnail)'),
                _buildPreviewAndPicker(),

                const SizedBox(height: 24),
                _buildSectionTitle('Tags (Categorias)'),
                _buildTagInput(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(_isEditing ? 'Salvar Alterações' : 'Publicar Conteúdo'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: Theme.of(context).textTheme.titleMedium,
                ),
              ),
        )
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).primaryColor)),
    );
  }

  Widget _buildFilePicker(String label, String? fileName, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: InputDecorator(
        decoration: const InputDecoration(),
        child: Row(
          children: [
            const Icon(Icons.attach_file, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text(fileName ?? label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewAndPicker() {
    Uint8List? thumbnailBytes = _pickedThumbnail?.bytes;
    return Column(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _isFetchingPreview
              ? const Center(child: CircularProgressIndicator())
              : thumbnailBytes != null
                ? Image.memory(thumbnailBytes, fit: BoxFit.cover)
                : _previewImageUrl != null
                  ? CachedNetworkImage(imageUrl: _previewImageUrl!, fit: BoxFit.cover, errorWidget: (_,__,___) => const Icon(Icons.image_not_supported))
                  : const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
          ),
        ),
        const SizedBox(height: 8),
        _buildFilePicker('Trocar imagem de capa', _pickedThumbnail?.name, () => _pickFile(true)),
      ],
    );
  }

  Widget _buildTagInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          children: _tagsSugeridas.map((tag) => FilterChip(
            label: Text(tag),
            selected: _tags.contains(tag),
            onSelected: (_) {
              setState(() {
                if (_tags.contains(tag)) _tags.remove(tag);
                else _tags.add(tag);
              });
            },
          )).toList(),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _tagController,
          decoration: InputDecoration(
            labelText: 'Adicionar nova tag',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addTag(_tagController.text),
            ),
          ),
          onFieldSubmitted: (value) => _addTag(value),
        ),
        const SizedBox(height: 8),
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 8.0,
            children: _tags.map((tag) => Chip(
              label: Text(tag),
              onDeleted: () => setState(() => _tags.remove(tag)),
            )).toList(),
          ),
      ],
    );
  }
}