import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String nome;
  final String? email;
  final bool emailVerified;
  final String? crm;
  final String? telefone;
  final String userType;
  final String? cpf;
  final String? status;

  AppUser({
    required this.uid,
    required this.nome,
    this.email,
    this.emailVerified = false,
    this.crm,
    this.telefone,
    required this.userType,
    this.cpf,
    this.status,
  });

  AppUser copyWith({
    String? uid,
    String? nome,
    String? email,
    bool? emailVerified,
    String? crm,
    String? telefone,
    String? userType,
    String? cpf,
    String? status,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      crm: crm ?? this.crm,
      telefone: telefone ?? this.telefone,
      userType: userType ?? this.userType,
      cpf: cpf ?? this.cpf,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nome': nome,
      'email': email,
      'crm': crm,
      'telefone': telefone,
      'userType': userType,
      'cpf': cpf,
      'status': status,
    };
  }

  factory AppUser.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser(
      uid: doc.id,
      nome: data['nome'] ?? '',
      email: data['email'],
      crm: data['crm'],
      telefone: data['telefone'],
      userType: data['userType'] ?? 'paciente',
      cpf: data['cpf'],
      status: data['status'],
    );
  }
}