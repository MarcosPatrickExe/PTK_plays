/// Validacao dos campos do cadastro em etapas (`lib/view/CriarConta.dart`).
///
/// Fica separada da UI por dois motivos: e a unica parte do fluxo que da
/// pra testar sem Firebase, e cada etapa precisa consultar a mesma regra
/// duas vezes — uma pra mostrar o aviso embaixo do campo enquanto a pessoa
/// digita, outra pra decidir se o botao "Avancar" libera. Sendo funcao
/// pura, as duas leituras nunca discordam.
///
/// Todas retornam null quando esta tudo certo, ou a mensagem pronta pra
/// aparecer embaixo do campo.
library;

import 'MascaraTelefoneWhatsapp.dart';

const int minimoCaracteresNickname = 3;
const int maximoCaracteresNickname = 20;
const int minimoCaracteresSenha = 6;

String? validarNickname(String nickname) {
  final valor = nickname.trim();
  if (valor.isEmpty) return 'Escolha um nick pra gente te chamar.';
  if (valor.length < minimoCaracteresNickname) {
    return 'O nick precisa de pelo menos $minimoCaracteresNickname letras.';
  }
  if (valor.length > maximoCaracteresNickname) {
    return 'O nick passou de $maximoCaracteresNickname caracteres.';
  }
  // O login aceita nick OU e-mail no mesmo campo, e o "@" e o que separa os
  // dois (ver AuthRepository._resolverEmailParaLogin). Um nick com "@" seria
  // lido como e-mail e nunca acharia a conta.
  if (valor.contains('@')) return 'O nick não pode ter @.';
  return null;
}

/// Formato de e-mail, de propósito permissivo: `algo@algo.algo`. Validacao
/// rigorosa de e-mail por regex e um poco sem fundo — quem diz de verdade
/// se o endereco existe e o e-mail de confirmacao.
String? validarEmail(String email) {
  final valor = email.trim();
  if (valor.isEmpty) return 'Preencha seu e-mail.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(valor)) {
    return 'Esse e-mail não parece válido.';
  }
  return null;
}

String? validarConfirmacaoEmail({required String email, required String confirmacao}) {
  if (confirmacao.trim().isEmpty) return 'Repita o e-mail pra confirmar.';
  if (email.trim().toLowerCase() != confirmacao.trim().toLowerCase()) {
    return 'Os e-mails não coincidem.';
  }
  return null;
}

String? validarSenha(String senha) {
  if (senha.isEmpty) return 'Crie uma senha.';
  if (senha.length < minimoCaracteresSenha) {
    return 'A senha precisa de pelo menos $minimoCaracteresSenha caracteres.';
  }
  return null;
}

String? validarConfirmacaoSenha({required String senha, required String confirmacao}) {
  if (confirmacao.isEmpty) return 'Repita a senha pra confirmar.';
  if (senha != confirmacao) return 'As senhas não coincidem.';
  return null;
}

/// Diferente de `validarTelefoneWhatsapp` (em AuthViewModel), que aceita o
/// campo vazio porque no cadastro antigo o WhatsApp era opcional: aqui ele
/// e obrigatorio.
String? validarWhatsappObrigatorio(String telefoneComMascara) {
  final digitos = MascaraTelefoneWhatsapp.digitosDe(telefoneComMascara);
  if (digitos.isEmpty) return 'Preencha seu número de WhatsApp.';
  if (digitos.length < MascaraTelefoneWhatsapp.digitosDeFixo) {
    return 'Número incompleto. Preencha o DDD e o número.';
  }
  return null;
}

/// A foto e obrigatoria, mas pode vir de dois lugares: um dos avatares
/// pre-definidos, ou uma foto tirada/escolhida pelo proprio usuario.
String? validarFotoEscolhida({required String? avatarPreset, required bool temFotoPropria}) {
  if (temFotoPropria) return null;
  if (avatarPreset != null && avatarPreset.isNotEmpty) return null;
  return 'Escolha um avatar ou tire uma foto.';
}
