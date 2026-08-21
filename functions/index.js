const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const { verificarHandshakeWebhook, assinaturaValida } = require('./src/webhook');

// Configurados via `firebase functions:secrets:set` (Secret Manager), nunca
// commitados. WHATSAPP_VERIFY_TOKEN e um valor arbitrario escolhido por nos,
// colado no formulario "Configurar webhooks" do Meta for Developers.
// WHATSAPP_APP_SECRET e a "Chave secreta do app" do painel do app no Meta.
const WHATSAPP_VERIFY_TOKEN = defineSecret('WHATSAPP_VERIFY_TOKEN');
const WHATSAPP_APP_SECRET = defineSecret('WHATSAPP_APP_SECRET');

/**
 * Endpoint de webhook do WhatsApp Business Platform (Meta).
 * GET: handshake de verificacao feito uma vez, quando a URL e cadastrada.
 * POST: eventos (status de mensagem, mensagens recebidas) enviados a cada
 * atualizacao. Por enquanto so confere a assinatura e loga o evento; a
 * logica de recuperacao de senha (enviar/verificar codigo) e implementada
 * em funcoes separadas, chamadas diretamente pelo app.
 */
exports.whatsappWebhook = onRequest(
  { secrets: [WHATSAPP_VERIFY_TOKEN, WHATSAPP_APP_SECRET] },
  (req, res) => {
    if (req.method === 'GET') {
      const resultado = verificarHandshakeWebhook({
        query: req.query,
        tokenEsperado: WHATSAPP_VERIFY_TOKEN.value(),
      });
      if (resultado.ok) {
        res.status(200).send(resultado.challenge);
      } else {
        logger.warn('Handshake do webhook do WhatsApp falhou.', { query: req.query });
        res.sendStatus(403);
      }
      return;
    }

    if (req.method === 'POST') {
      const valido = assinaturaValida({
        corpoBruto: req.rawBody,
        headerAssinatura: req.get('X-Hub-Signature-256'),
        appSecret: WHATSAPP_APP_SECRET.value(),
      });
      if (!valido) {
        logger.warn('Webhook do WhatsApp recebeu POST com assinatura invalida.');
        res.sendStatus(403);
        return;
      }
      logger.info('Evento do WhatsApp recebido.', { body: req.body });
      res.sendStatus(200);
      return;
    }

    res.sendStatus(405);
  },
);
