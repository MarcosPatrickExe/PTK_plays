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

module.exports = { verificarHandshakeWebhook, assinaturaValida };
