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

/// Quantas letras o nick precisa ter pro botao "Avancar" **aparecer**.
///
/// E menor que [minimoCaracteresNickname] de proposito. O botao surgindo na
/// segunda letra e o sinal de que a tela esta reagindo ao que a pessoa
/// digita; a terceira letra e o que de fato libera o avanco. Se os dois
/// numeros fossem iguais, o botao apareceria ja clicavel e o movimento nao
/// diria nada — apareceu, entao pode clicar, e nao "voce esta quase la".
const int minimoParaMostrarAvancar = 2;

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

// Nao existe `validarConfirmacaoSenha`, e isso e deliberado (14/set/2026).
//
// O campo "Confirme a senha" saiu do cadastro. Ele nasceu numa epoca em que
// senha era sempre mascarada e digitar errado so aparecia no proximo login —
// repetir era a unica defesa. Aqui o campo tem o olho: da pra ler o que foi
// digitado antes de seguir, e a defesa ja esta no lugar sem custar uma
// segunda digitacao.
//
// **O "Confirme o e-mail" continua** (`validarConfirmacaoEmail`), e a
// assimetria e o ponto: e-mail errado nao tem conserto de dentro do app —
// a recuperacao de senha vai pro endereco errado e a conta fica orfa. Senha
// errada tem: e so pedir pra redefinir, justamente pelo e-mail.

/// WhatsApp e **opcional** desde 13/set: campo vazio passa.
///
/// Ele era obrigatorio, e isso era risco de reprovacao 5.1.1(ii) — a Apple
/// recusa app que EXIGE dado pessoal nao essencial ao que o app faz, e ver
/// feed, videos e avisos de live nao precisa de telefone. Exigir logo depois
/// de a pessoa escolher "Hide My Email" piorava o quadro.
///
/// O que continua barrado e o numero **pela metade**: melhor nenhum numero
/// do que um que nao chama.
String? validarWhatsappOpcional(String telefoneComMascara) {
  final digitos = MascaraTelefoneWhatsapp.digitosDe(telefoneComMascara);
  if (digitos.isEmpty) return null;
  if (digitos.length < MascaraTelefoneWhatsapp.digitosDeFixo) {
    return 'Número incompleto. Preencha o DDD e o número, ou pule esta etapa.';
  }
  return null;
}

/// Se o WhatsApp foi preenchido por inteiro — e nao so comecado.
bool whatsappCompleto(String telefoneComMascara) {
  final digitos = MascaraTelefoneWhatsapp.digitosDe(telefoneComMascara);
  return digitos.length >= MascaraTelefoneWhatsapp.digitosDeFixo;
}

/// A foto e obrigatoria, mas pode vir de dois lugares: um dos avatares
/// pre-definidos, ou uma foto tirada/escolhida pelo proprio usuario.
String? validarFotoEscolhida({required String? avatarPreset, required bool temFotoPropria}) {
  if (temFotoPropria) return null;
  if (avatarPreset != null && avatarPreset.isNotEmpty) return null;
  return 'Escolha um avatar ou tire uma foto.';
}
