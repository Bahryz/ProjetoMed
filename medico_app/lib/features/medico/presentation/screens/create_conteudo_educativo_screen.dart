// medico_app/lib/features/medico/presentation/screens/create_conteudo_educativo_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:medico_app/features/medico/data/models/conteudo_educativo_model.dart';
import 'package:medico_app/features/medico/data/services/conteudo_educativo_service.dart';

class CreateConteudoEducativoScreen extends StatefulWidget {
  const CreateConteudoEducativoScreen({super.key});

  @override
  State<CreateConteudoEducativoScreen> createState() => _CreateConteudoEducativoScreenState();
}

class _CreateConteudoEducativoScreenState extends State<CreateConteudoEducativoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _urlController = TextEditingController();

  ConteudoTipo _tipoSelecionado = ConteudoTipo.artigo;
  String? _filePath;
  String? _thumbnailPath;
  bool _isUploading = false;
  final _service = ConteudoEducativoService();

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _filePath = result.files.single.path;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isUploading = true);
    
    try {
      String fileUrl = _urlController.text.trim();
      String? thumbnailUrl;

      // Lógica de upload do arquivo para o Firebase Storage, se um arquivo local for selecionado
      if (_filePath != null) {
        // Exemplo simplificado de upload. O serviço de upload precisaria ser implementado.
        // fileUrl = await _service.uploadFile(File(_filePath!), 'conteudo_educativo/files/${_filePath!.split('/').last}');
        // Se for um arquivo local, a URL acima seria a do Storage. Por enquanto, usamos a URL digitada.
      }
      
      await _service.addConteudo(
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        tipo: _tipoSelecionado,
        url: fileUrl,
        thumbnailUrl: thumbnailUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conteúdo adicionado com sucesso!')),
        );
        context.pop(); // Volta para a tela anterior
      }
    } catch (e) {
      debugPrint("Erro ao enviar conteúdo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar conteúdo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Conteúdo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título do Conteúdo'),
                validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ConteudoTipo>(
                value: _tipoSelecionado,
                decoration: const InputDecoration(labelText: 'Tipo de Conteúdo'),
                items: ConteudoTipo.values.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(tipo.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() => _tipoSelecionado = newValue);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL do Conteúdo (YouTube, Artigo, PDF)',
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Campo obrigatório';
                  // Adicionar validação de URL mais robusta, se necessário
                  return null;
                },
              ),
              const SizedBox(height: 30),
              _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar Conteúdo'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}