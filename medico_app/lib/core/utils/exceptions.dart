// Exceção base para erros de autenticação
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message; // Para exibir a mensagem diretamente
}

// Exceções específicas
class EmailAlreadyInUseAuthException extends AuthException {
  EmailAlreadyInUseAuthException() : super('Este e-mail já está em uso.');
}

class WeakPasswordAuthException extends AuthException {
  WeakPasswordAuthException() : super('A senha fornecida é muito fraca.');
}

class WrongPasswordAuthException extends AuthException {
  WrongPasswordAuthException() : super('A senha ou e-mail estão incorretos.');
}

class UserNotFoundAuthException extends AuthException {
  UserNotFoundAuthException() : super('Nenhum usuário encontrado com este e-mail.');
}