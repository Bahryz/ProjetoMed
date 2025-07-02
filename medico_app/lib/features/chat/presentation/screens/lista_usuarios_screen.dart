import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medico_app/features/authentication/data/models/app_user.dart';
import 'package:medico_app/features/chat/services/user_service.dart';

class ListaUsuariosScreen extends ConsumerStatefulWidget {
  const ListaUsuariosScreen({super.key});

  @override
  ConsumerState<ListaUsuariosScreen> createState() => _ListaUsuariosScreenState();
}

class _ListaUsuariosScreenState extends ConsumerState<ListaUsuariosScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientsStream = ref.watch(patientsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pacientes'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar paciente...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
            ),
          ),
          Expanded(
            child: patientsStream.when(
              data: (users) {
                final filteredUsers = users.where((user) {
                  return user.nome.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Text('Nenhum paciente encontrado.'),
                  );
                }
                
                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserTile(user);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Erro ao carregar pacientes: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildUserTile(AppUser user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Text(
              user.nome.isNotEmpty ? user.nome[0].toUpperCase() : 'P',
              style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(user.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('Paciente - Toque para conversar'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
             context.go('/chat', extra: user);
          },
        ),
      ),
    );
  }
}
