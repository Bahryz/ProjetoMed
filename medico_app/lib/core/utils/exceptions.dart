// Exceção base para erros de autenticação
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

// Exceções específicas
class EmailAlreadyInUseAuthException extends AuthException {
  EmailAlreadyInUseAuthException() : super('Este e-mail já está em uso.');
}

class WeakPasswordAuthException extends AuthException {
  WeakPasswordAuthException() : super('A senha fornecida é muito fraca.');
}

class WrongPasswordAuthException extends AuthException {
  WrongPasswordAuthException() : super('A senha está incorreta.');
}

class UserNotFoundAuthException extends AuthException {
  UserNotFoundAuthException() : super('Nenhum usuário encontrado com este e-mail.');
}