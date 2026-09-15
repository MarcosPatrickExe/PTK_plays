'use strict';

const crypto = require('crypto');

/**
 * A logica pura do pre-teste de e-mail repetido, separada do `onCall` pra
 * poder ser testada sem Firebase nenhum (ver test/preTesteDeEmail.test.js).
 *
 * O que o pre-teste resolve: ate 15/set o "esse e-mail ja tem conta" so
 * aparecia NO FIM do cadastro, quando o Firebase recusava o
 * `createUserWithEmailAndPassword` — depois de a pessoa ja ter escolhido
 * nick, senha, foto e WhatsApp.
 *
 * **Por que isso vive numa Cloud Function, e nao numa consulta do app.**
 * Perguntar "esse e-mail tem conta?" e, por definicao, um oraculo de
 * enumeracao. A primeira versao consultava a colecao `nicknamesParaEmail`
 * direto do cliente, o que exigia deixar aquela colecao **listavel por
 * qualquer um** — e ela guarda o e-mail de todo mundo. Aqui o servidor
 * responde so um booleano, ninguem ve a base, e da pra limitar quantas
 * perguntas cada um faz.
 *
 * O `getUserByEmail` do Admin SDK tambem responde melhor que a consulta ao
 * Firestore: ele enxerga **toda** conta do Auth, inclusive a de quem entrou
 * pelo Google/Apple e abandonou o cadastro antes de reservar o nick — caso
 * que a versao anterior deixava passar por livre.
 */

/** Minusculas e sem espaco, do mesmo jeito que o Firebase Auth guarda. */
function normalizarEmail(valor) {
  if (typeof valor !== 'string') return '';
  return valor.trim().toLowerCase();
}

/**
 * Formato de e-mail, de proposito permissivo: `algo@algo.algo`.
 *
 * Nao existe pra validar de verdade — quem faz isso e a tela, e depois o
 * proprio Auth. Existe pra **nao gastar uma consulta ao Auth** (e uma vaga
 * no limite de quem chamou) com texto que nao tem chance nenhuma de ser
 * um endereco.
 */
function emailPareceValido(email) {
  return /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);
}

/**
 * O identificador de quem esta perguntando, pro controle de frequencia.
 *
 * **E um hash, e nao o IP.** O IP e dado pessoal, e guardar uma lista deles
 * pra contar requisicao seria criar um registro de quem tentou se cadastrar
 * e quando — dado que ninguem pediu e que teria que ser protegido. O hash
 * serve igual pra contar e nao serve pra identificar ninguem depois.
 *
 * A janela entra na chave em vez de virar um campo: assim cada intervalo
 * comeca num documento novo, sem precisar de transacao pra "zerar" o
 * contador quando o relogio vira.
 */
function chaveDeFrequencia(ip, agoraEmMs, janelaEmMs) {
  const janela = Math.floor(agoraEmMs / janelaEmMs);
  const digest = crypto.createHash('sha256').update(String(ip || 'sem-ip')).digest('hex');
  return `${digest.slice(0, 32)}_${janela}`;
}

/** Quanto tempo uma janela de contagem dura. */
const JANELA_EM_MS = 60 * 60 * 1000;

/**
 * Quantas perguntas cada origem pode fazer por janela.
 *
 * Folgado de proposito pra gente de verdade: um cadastro faz **uma**
 * consulta, e mesmo quem erra o endereco varias vezes nao chega perto de
 * 30 numa hora. O numero existe pra quebrar o script que testaria milhoes
 * de enderecos, nao pra apertar quem esta se cadastrando.
 *
 * **Isto nao substitui o App Check**, que e a defesa de verdade (so o app
 * de verdade consegue chamar). Enquanto ele nao estiver ligado no Console,
 * este limite e o que existe.
 */
const LIMITE_POR_JANELA = 30;

/**
 * Decide se a pergunta passa, dado quantas ja foram feitas nesta janela.
 *
 * Recebe a contagem em vez de ler o banco pra continuar testavel: quem le
 * e grava e o `onCall`.
 */
function dentroDoLimite(contagemAtual, limite = LIMITE_POR_JANELA) {
  return (contagemAtual || 0) < limite;
}

/**
 * A resposta do pre-teste pra um e-mail que nem chega a ser consultado.
 *
 * **Devolve "nao existe", e nao um erro.** O pre-teste e uma gentileza pra
 * avisar cedo; quem barra o duplicado de verdade e o Auth, no fim do fluxo.
 * Responder erro aqui faria o cadastro parar por causa de uma checagem que
 * era opcional desde o começo.
 */
const RESPOSTA_LIVRE = { existe: false };

module.exports = {
  normalizarEmail,
  emailPareceValido,
  chaveDeFrequencia,
  dentroDoLimite,
  JANELA_EM_MS,
  LIMITE_POR_JANELA,
  RESPOSTA_LIVRE,
};
