const { onRequest } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { defineSecret } = require('firebase-functions/params');
const { initializeApp } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const logger = require('firebase-functions/logger');
const { getFirestore } = require('firebase-admin/firestore');
const { verificarHandshakeWebhook, assinaturaValida, extrairEventosDoWebhook } = require('./src/webhook');
const { verificarYoutubeAoVivo } = require('./lib/youtube');
const { twitchWebhook } = require('./lib/twitch');
const { kickWebhook, kickAuthStart, kickOAuthCallback } = require('./lib/kick');

initializeApp();

// Configurados via `firebase functions:secrets:set` (Secret Manager), nunca
// commitados. WHATSAPP_VERIFY_TOKEN e um valor arbitrario escolhido por nos,
// colado no formulario "Configurar webhooks" do Meta for Developers.
// WHATSAPP_APP_SECRET e a "Chave secreta do app" do painel do app no Meta.
const WHATSAPP_VERIFY_TOKEN = defineSecret('WHATSAPP_VERIFY_TOKEN');
const WHATSAPP_APP_SECRET = defineSecret('WHATSAPP_APP_SECRET');

// Caixa de entrada do WhatsApp, lida pela aba WhatsApp do Painel ADM.
//
// Guardar isso aqui nao e capricho: a Cloud API **nao tem endpoint de
// historico**. A Meta entrega cada evento uma vez, no webhook, e nao guarda
// nada pra gente consultar depois. O que nao for gravado neste momento se
// perde — e como o numero de producao fica sob controle da API, tambem nao
// da pra abrir o app do WhatsApp e ver a conversa por la.
const COLECAO_MENSAGENS = 'mensagensWhatsapp';

/**
 * Grava os eventos do webhook em `mensagensWhatsapp`, um documento por
 * mensagem (id = wamid, ver `extrairEventosDoWebhook`).
 *
 * `merge: true` porque o mesmo documento e escrito mais de uma vez: a
 * mensagem sai, depois chega `sent`, depois `delivered`, depois `read` —
 * cada um atualizando o mesmo registro em vez de criar um novo.
 *
 * Uma falha aqui **nao** derruba a resposta 200 pro webhook: a Meta
 * reenvia o evento quando nao recebe 200, e reenvio em cima de um erro de
 * escrita permanente viraria loop. Falhou, fica o log.
 */
async function gravarEventosDoWhatsapp(corpo) {
  const eventos = extrairEventosDoWebhook(corpo);
  if (eventos.length === 0) return;

  const db = getFirestore();
  const lote = db.batch();
  for (const evento of eventos) {
    lote.set(db.collection(COLECAO_MENSAGENS).doc(evento.docId), evento.dados, { merge: true });
  }
  await lote.commit();
  logger.info(`[whatsapp] ${eventos.length} evento(s) gravado(s) em ${COLECAO_MENSAGENS}.`);
}

/**
 * Endpoint de webhook do WhatsApp Business Platform (Meta).
 * GET: handshake de verificacao feito uma vez, quando a URL e cadastrada.
 * POST: eventos (status de mensagem, mensagens recebidas) enviados a cada
 * atualizacao — conferidos pela assinatura e gravados na caixa de entrada.
 * A logica de recuperacao de senha (enviar/verificar codigo) e implementada
 * em funcoes separadas, chamadas diretamente pelo app.
 */
exports.whatsappWebhook = onRequest(
  { secrets: [WHATSAPP_VERIFY_TOKEN, WHATSAPP_APP_SECRET] },
  async (req, res) => {
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
      // Responde 200 antes de gravar: a Meta reenvia o evento se nao
      // receber 200 rapido, e um reenvio nao consertaria uma falha de
      // escrita — so duplicaria o trabalho.
      res.sendStatus(200);
      try {
        await gravarEventosDoWhatsapp(req.body);
      } catch (erro) {
        logger.error('Falha ao gravar evento do WhatsApp.', { erro: String(erro), body: req.body });
      }
      return;
    }

    res.sendStatus(405);
  },
);

exports.verificarYoutubeAoVivo = verificarYoutubeAoVivo;
exports.twitchWebhook = twitchWebhook;
exports.kickWebhook = kickWebhook;
exports.kickAuthStart = kickAuthStart;
exports.kickOAuthCallback = kickOAuthCallback;

const TOPICO_AO_VIVO = 'ao_vivo';

/**
 * Dispara quando um post novo e criado em `posts/{postId}`. Se for do tipo
 * "aoVivo", manda uma notificacao push pro topico `ao_vivo` (todo app
 * inscrito nesse topico recebe). O data.postId vai junto pra o app saber
 * pra qual card do Feed rolar quando o usuario tocar na notificacao.
 *
 * Regiao southamerica-east1 explicita (mesma do Firestore/das outras
 * functions de live) - nao usamos `setGlobalOptions` pra isso porque isso
 * mudaria tambem a regiao do `whatsappWebhook` (que ja esta deployado sem
 * regiao explicita, ou seja em us-central1) e quebraria a URL cadastrada
 * no Meta for Developers.
 */
exports.notificarAoVivo = onDocumentCreated(
  { document: 'posts/{postId}', region: 'southamerica-east1' },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const post = snapshot.data();
    if (!post || post.tipo !== 'aoVivo') return;

    const corpo = post.texto || 'Corre pra assistir agora!';

    await getMessaging().send({
      topic: TOPICO_AO_VIVO,
      notification: {
        title: 'PTK Plays está AO VIVO! 🔴',
        body: corpo,
      },
      data: {
        postId: event.params.postId,
        tipo: 'aoVivo',
      },
      android: {
        priority: 'high',
        notification: { sound: 'default' },
      },
      apns: {
        payload: {
          aps: { sound: 'default' },
        },
      },
    });
  },
);
