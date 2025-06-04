class AppUser {
  final String uid;
  final String email;
  final String nome;
  final String userType; // 'medico' ou 'paciente'
  final String? crm; // Opcional, apenas para médicos
  final String? cpf; // Opcional, apenas para pacientes

  AppUser({
    required this.uid,
    required this.email,
    required this.nome,
    required this.userType,
    this.crm,
    this.cpf,
  });

  // Método para criar um AppUser a partir de um mapa (vindo do Firestore)
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'],
      email: map['email'],
      nome: map['nome'],
      userType: map['userType'],
      crm: map['crm'],
      cpf: map['cpf'],
    );
  }

  // Método para converter um AppUser em um mapa (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nome': nome,
      'userType': userType,
      'crm': crm,
      'cpf': cpf,
    };
  }
}