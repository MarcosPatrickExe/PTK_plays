const crypto = require('crypto');

/**
 * Valida o handshake de verificacao do Webhook do WhatsApp (GET com
 * hub.mode=subscribe, hub.verify_token, hub.challenge), exigido pela Meta
 * antes de aceitar a URL de callback configurada no app. Extraida como
 * funcao pura pra ser testada sem precisar de um request HTTP de verdade.
 */
function verificarHandshakeWebhook({ query, tokenEsperado }) {
  const modo = query['hub.mode'];
  const token = query['hub.verify_token'];
  const challenge = query['hub.challenge'];

  if (modo === 'subscribe' && token === tokenEsperado && challenge) {
    return { ok: true, challenge };
  }
  return { ok: false };
}

/**
 * Confere a assinatura HMAC-SHA256 (header X-Hub-Signature-256) que a Meta
 * envia em todo POST de webhook, calculada com o App Secret. Sem isso,
 * qualquer pessoa que descobrisse a URL publica do webhook poderia mandar
 * eventos falsos pro nosso backend.
 */
function assinaturaValida({ corpoBruto, headerAssinatura, appSecret }) {
  if (!headerAssinatura || !headerAssinatura.startsWith('sha256=')) return false;

  const assinaturaRecebida = headerAssinatura.slice('sha256='.length);
  const assinaturaEsperada = crypto.createHmac('sha256', appSecret).update(corpoBruto).digest('hex');

  const bufferRecebido = Buffer.from(assinaturaRecebida, 'hex');
  const bufferEsperado = Buffer.from(assinaturaEsperada, 'hex');
  if (bufferRecebido.length !== bufferEsperado.length) return false;

  return crypto.timingSafeEqual(bufferRecebido, bufferEsperado);
}

/**
 * Transforma o corpo de um POST do webhook nos documentos que a gente quer
 * gravar na colecao `mensagensWhatsapp`.
 *
 * E funcao pura de proposito: o formato da Meta e aninhado
 * (`entry[].changes[].value`) e vem em dois sabores no mesmo envelope —
 * `messages` (o que as pessoas mandaram pra gente) e `statuses` (o que
 * aconteceu com o que a gente mandou pra elas). Testar isso com payloads
 * de verdade e muito mais barato do que subir emulador.
 *
 * **Por que o id do documento e o wamid**: um status (`sent`, `delivered`,
 * `read`, `failed`) chega depois, referenciando pelo `id` a mensagem que
 * ja saiu. Usando o proprio wamid como id do documento, o status cai em
 * cima do registro certo com `merge` — sem precisar procurar, e sem
 * duplicar a mesma mensagem em varios documentos.
 */
function extrairEventosDoWebhook(corpo) {
  const eventos = [];
  const entradas = (corpo && corpo.entry) || [];

  for (const entrada of entradas) {
    for (const mudanca of entrada.changes || []) {
      const valor = mudanca.value || {};

      // wa_id -> nome do perfil, pra caixa de entrada nao virar uma lista
      // de numeros. So vem junto das mensagens recebidas.
      const nomePorTelefone = {};
      for (const contato of valor.contacts || []) {
        if (contato.wa_id && contato.profile && contato.profile.name) {
          nomePorTelefone[contato.wa_id] = contato.profile.name;
        }
      }

      for (const mensagem of valor.messages || []) {
        if (!mensagem.id) continue;
        eventos.push({
          docId: idDocumentoMensagem(mensagem.id),
          dados: {
            idNaMeta: mensagem.id,
            telefone: mensagem.from || '',
            nomeDoContato: nomePorTelefone[mensagem.from] || '',
            direcao: 'recebida',
            tipo: mensagem.type || 'desconhecido',
            texto: textoDaMensagem(mensagem),
            criadaEm: dataDoTimestamp(mensagem.timestamp),
            atualizadaEm: dataDoTimestamp(mensagem.timestamp),
          },
        });
      }

      for (const status of valor.statuses || []) {
        if (!status.id) continue;
        const erro = (status.errors || [])[0];
        eventos.push({
          docId: idDocumentoMensagem(status.id),
          dados: {
            idNaMeta: status.id,
            telefone: status.recipient_id || '',
            direcao: 'enviada',
            status: status.status || '',
            // Sem `criadaEm`: o documento pode nascer aqui (o envio ainda
            // nao grava nada) e a data do status nao e a data do envio.
            // A caixa de entrada ordena por `atualizadaEm`, que e o que
            // interessa numa lista de conversas: atividade mais recente
            // primeiro.
            atualizadaEm: dataDoTimestamp(status.timestamp),
            ...(erro ? { erro: [erro.code, erro.title].filter(Boolean).join(' - ') } : {}),
          },
        });
      }
    }
  }

  return eventos;
}

/**
 * O wamid vem em base64 e pode trazer "/", que o Firestore nao aceita em id
 * de documento. Trocar por "_" mantem o id deterministico (mesma mensagem,
 * mesmo documento) sem perder unicidade.
 */
function idDocumentoMensagem(wamid) {
  return String(wamid).replace(/\//g, '_');
}

/**
 * O texto legivel da mensagem, quando existe. Midia sem legenda devolve
 * string vazia de proposito — quem mostra "[imagem]" e a UI, a partir do
 * `tipo`, em vez de a gente inventar um texto que a pessoa nao escreveu.
 */
function textoDaMensagem(mensagem) {
  if (mensagem.text && mensagem.text.body) return mensagem.text.body;
  if (mensagem.button && mensagem.button.text) return mensagem.button.text;
  for (const midia of ['image', 'video', 'document', 'audio']) {
    if (mensagem[midia] && mensagem[midia].caption) return mensagem[midia].caption;
  }
  return '';
}

/** O timestamp da Meta vem em segundos, como string. */
function dataDoTimestamp(timestamp) {
  const segundos = Number(timestamp);
  if (!Number.isFinite(segundos) || segundos <= 0) return new Date();
  return new Date(segundos * 1000);
}

module.exports = {
  verificarHandshakeWebhook,
  assinaturaValida,
  extrairEventosDoWebhook,
  idDocumentoMensagem,
};
