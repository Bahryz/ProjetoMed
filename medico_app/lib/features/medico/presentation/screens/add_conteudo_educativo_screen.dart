import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medico_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:medico_app/features/medico/data/services/conteudo_educativo_service.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:provider/provider.dart';

enum InputType { url, file }

class AddConteudoEducativoScreen extends StatefulWidget {
  const AddConteudoEducativoScreen({super.key});

  @override
  State<AddConteudoEducativoScreen> createState() =>
      _AddConteudoEducativoScreenState();
}

class _AddConteudoEducativoScreenState
    extends State<AddConteudoEducativoScreen> {
  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _urlController = TextEditingController();
  final _tagController = TextEditingController();
  final _urlFocusNode = FocusNode();

  // State
  InputType _inputType = InputType.url;
  bool _isLoading = false;
  bool _isFetchingPreview = false;
  Metadata? _urlMetadata;
  PlatformFile? _pickedFile;
  PlatformFile? _pickedThumbnail;

  // Tags
  final List<String> _tags = [];
  final List<String> _tagsSugeridas = ['Artigo', 'Vídeo', 'PDF', 'Exercícios'];

  final _service = ConteudoEducativoService();

  @override
  void initState() {
    super.initState();
    _urlFocusNode.addListener(_onUrlFocusChange);
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
    if (!_urlFocusNode.hasFocus) {
      _fetchUrlPreview();
    }
  }

  Future<void> _fetchUrlPreview() async {
    final url = _urlController.text.trim();
    if (url.isNotEmpty && Uri.tryParse(url)?.isAbsolute == true) {
      setState(() {
        _isFetchingPreview = true;
        _urlMetadata = null;
      });
      try {
        final data = await MetadataFetch.extract(url);
        if (mounted) {
          setState(() {
            _urlMetadata = data;
            final title = data?.title;
            final description = data?.description;
            if (title != null) {
              _tituloController.text = title;
            }
            if (description != null) {
              _descricaoController.text = description;
            }
          });
        }
      } catch (e) {
        debugPrint('Erro ao buscar preview da URL: $e');
      } finally {
        if (mounted) {
          setState(() => _isFetchingPreview = false);
        }
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
          _tituloController.text = _pickedFile!.name;
        }
      });
    }
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _tags.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Preencha todos os campos e adicione pelo menos uma tag.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    final medicoId = context.read<AuthController>().user?.uid;
    if (medicoId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Erro de autenticação.')));
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      String finalUrl = '';
      String? thumbnailUrl;

      // Upload de thumbnail se houver
      if (_pickedThumbnail != null) {
        thumbnailUrl = await _service.uploadFile(
          fileBytes: _pickedThumbnail!.bytes!,
          fileName: _pickedThumbnail!.name,
          medicoId: medicoId,
        );
      } else {
        thumbnailUrl = _urlMetadata?.image;
      }

      // Lógica de URL vs. Upload de Arquivo
      if (_inputType == InputType.url) {
        finalUrl = _urlController.text.trim();
      } else if (_pickedFile != null) {
        finalUrl = await _service.uploadFile(
          fileBytes: _pickedFile!.bytes!,
          fileName: _pickedFile!.name,
          medicoId: medicoId,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Por favor, selecione um arquivo.')));
        }
        setState(() => _isLoading = false);
        return;
      }

      await _service.addConteudo(
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        tags: _tags,
        url: finalUrl,
        thumbnailUrl: thumbnailUrl,
        medicoId: medicoId,
      );

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Conteúdo'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Tipo de Conteúdo'),
              SegmentedButton<InputType>(
                segments: const [
                  ButtonSegment(
                      value: InputType.url,
                      label: Text('Link Externo'),
                      icon: Icon(Icons.link)),
                  ButtonSegment(
                      value: InputType.file,
                      label: Text('Arquivo'),
                      icon: Icon(Icons.upload_file)),
                ],
                selected: {_inputType},
                onSelectionChanged: (newSelection) {
                  setState(() => _inputType = newSelection.first);
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Detalhes'),
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 24),
              if (_inputType == InputType.url)
                TextFormField(
                  controller: _urlController,
                  focusNode: _urlFocusNode,
                  decoration: const InputDecoration(labelText: 'URL do Conteúdo'),
                  keyboardType: TextInputType.url,
                  validator: (v) => (v!.isEmpty ||
                          Uri.tryParse(v)?.isAbsolute != true)
                      ? 'URL inválida'
                      : null,
                ),
              if (_inputType == InputType.file) _buildFilePicker(),
              const SizedBox(height: 16),
              _buildPreviewCard(),
              const SizedBox(height: 24),
              _buildSectionTitle('Thumbnail (Opcional)'),
              _buildThumbnailPicker(),
              const SizedBox(height: 24),
              _buildSectionTitle('Tags'),
              _buildTagInput(),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Salvar Conteúdo'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets de Construção da UI ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _buildFilePicker() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.attach_file),
      label: Text(_pickedFile?.name ?? 'Selecionar arquivo do dispositivo'),
      onPressed: () => _pickFile(false),
    );
  }

  Widget _buildThumbnailPicker() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.image_outlined),
      label: Text(_pickedThumbnail?.name ?? 'Selecionar imagem de capa'),
      onPressed: () => _pickFile(true),
    );
  }

  Widget _buildPreviewCard() {
    if (_isFetchingPreview) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_urlMetadata == null || _urlMetadata?.image == null) {
      return const SizedBox.shrink();
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Image.network(
            _urlMetadata!.image!,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.hide_image_outlined, size: 40)),
          ),
          ListTile(
            title: Text(_urlMetadata!.title ?? 'Sem Título'),
            subtitle:
                Text(_urlMetadata!.description ?? 'Sem Descrição', maxLines: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildTagInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          children: _tagsSugeridas
              .map((tag) => FilterChip(
                    label: Text(tag),
                    selected: _tags.contains(tag),
                    onSelected: (_) {
                      setState(() {
                        if (_tags.contains(tag)) {
                          _tags.remove(tag);
                        } else {
                          _tags.add(tag);
                        }
                      });
                    },
                  ))
              .toList(),
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
        Wrap(
          spacing: 8.0,
          children: _tags
              .map((tag) => Chip(
                    label: Text(tag),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

