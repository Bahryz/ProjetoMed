class AppUser {
  final String uid;
  final String? nome;
  final String? email;
  final String? telefone;
  final String? cpf;
  final String? crm;
  final String userType;

  AppUser({
    required this.uid,
    this.nome,
    this.email,
    this.telefone,
    this.cpf,
    this.crm,
    required this.userType,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      nome: map['nome'],
      email: map['email'],
      telefone: map['telefone'],
      cpf: map['cpf'],
      crm: map['crm'],
      userType: map['userType'] ?? 'paciente',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'cpf': cpf,
      'crm': crm,
      'userType': userType,
    };
  }

  AppUser copyWith({
    String? uid,
    String? nome,
    String? email,
    String? telefone,
    String? cpf,
    String? crm,
    String? userType,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      cpf: cpf ?? this.cpf,
      crm: crm ?? this.crm,
      userType: userType ?? this.userType,
    );
  }
}