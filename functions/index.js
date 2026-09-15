const { onRequest, onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { defineSecret } = require('firebase-functions/params');
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getMessaging } = require('firebase-admin/messaging');
const logger = require('firebase-functions/logger');
const { getFirestore } = require('firebase-admin/firestore');
const { verificarHandshakeWebhook, assinaturaValida, extrairEventosDoWebhook } = require('./src/webhook');
const {
  normalizarEmail,
  emailPareceValido,
  chaveDeFrequencia,
  dentroDoLimite,
  JANELA_EM_MS,
  RESPOSTA_LIVRE,
} = require('./src/preTesteDeEmail');
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

// Onde ficam os contadores do controle de frequencia do pre-teste. Cada
// documento e uma origem numa janela de uma hora (ver chaveDeFrequencia), e
// carrega `expiraEm` pra uma politica de TTL do Firestore poder varrer os
// antigos. **Sem essa politica configurada no Console, os documentos so
// acumulam** — sao pequenos, mas acumulam.
const COLECAO_LIMITE_PRE_TESTE = 'limitesDePreTesteDeEmail';

/**
 * Responde se ja existe conta com um e-mail. So isso: um booleano.
 *
 * Existe pra pessoa descobrir **na etapa de e-mail** que ja tem conta, e
 * nao no fim do cadastro — depois de ja ter escolhido nick, senha, foto e
 * WhatsApp. Perder tudo isso pra descobrir que era so entrar e o que faz
 * desistir em vez de voltar.
 *
 * **Por que uma funcao, e nao uma consulta do app.** Perguntar "esse e-mail
 * tem conta?" e um oraculo de enumeracao por definicao. A versao anterior
 * consultava `nicknamesParaEmail` direto do cliente, e pra isso aquela
 * colecao precisava ficar **listavel por qualquer um** — ela guarda o
 * e-mail de todo mundo. Aqui o servidor devolve so o booleano, a colecao
 * voltou a ser fechada pra listagem, e da pra contar quantas perguntas cada
 * origem faz.
 *
 * `getUserByEmail` tambem responde melhor que a consulta ao Firestore: ele
 * enxerga toda conta do Auth, inclusive a de quem entrou pelo Google/Apple
 * e abandonou o cadastro antes de reservar o nick — caso que a consulta
 * deixava passar por livre.
 *
 * **Regiao declarada aqui, e nunca via setGlobalOptions**: o global moveria
 * o `whatsappWebhook` de us-central1 e quebraria a URL cadastrada na Meta.
 *
 * **Falha de infraestrutura responde "nao existe"**, e nao erro. O
 * pre-teste e uma gentileza pra avisar cedo; quem barra o duplicado de
 * verdade e o Auth, no `createUserWithEmailAndPassword`. Derrubar o
 * cadastro porque o Firestore piscou seria trocar um aviso antecipado por
 * uma porta fechada.
 */
exports.emailJaCadastrado = onCall(
  { region: 'southamerica-east1', cors: true },
  async (request) => {
    const email = normalizarEmail(request.data && request.data.email);

    // Texto que nao tem chance de ser endereco nao gasta consulta ao Auth
    // nem vaga no limite de quem chamou.
    if (!emailPareceValido(email)) return RESPOSTA_LIVRE;

    const passou = await registrarPerguntaDoPreTeste(request.rawRequest && request.rawRequest.ip);
    if (!passou) {
      // Este SIM e erro, e proposital: chegar aqui significa que alguem
      // esta varrendo enderecos, e o app de verdade nunca chega perto do
      // limite. O cliente trata como "nao sei" e segue o cadastro.
      throw new HttpsError('resource-exhausted', 'Muitas consultas seguidas.');
    }

    try {
      await getAuth().getUserByEmail(email);
      return { existe: true };
    } catch (erro) {
      if (erro && erro.code === 'auth/user-not-found') return RESPOSTA_LIVRE;
      logger.error('pre-teste de e-mail falhou', erro);
      return RESPOSTA_LIVRE;
    }
  },
);

/**
 * Conta mais uma pergunta pra esta origem e diz se ela cabia no limite.
 *
 * Usa transacao porque duas chamadas simultaneas da mesma origem leriam o
 * mesmo contador e gravariam o mesmo valor — e o limite viraria decorativo
 * justamente sob a carga que ele existe pra conter.
 *
 * Falha de leitura/escrita **libera** a pergunta: um limite que nao
 * consegue contar nao pode virar um cadastro que nao acontece.
 */
async function registrarPerguntaDoPreTeste(ip) {
  const agora = Date.now();
  const chave = chaveDeFrequencia(ip, agora, JANELA_EM_MS);
  const db = getFirestore();
  const ref = db.collection(COLECAO_LIMITE_PRE_TESTE).doc(chave);

  try {
    return await db.runTransaction(async (transacao) => {
      const doc = await transacao.get(ref);
      const contagem = doc.exists ? doc.data().contagem || 0 : 0;

      if (!dentroDoLimite(contagem)) return false;

      transacao.set(ref, {
        contagem: contagem + 1,
        // Pra uma politica de TTL do Firestore varrer sozinha. Sem a
        // politica configurada, o campo e so informativo.
        expiraEm: new Date(agora + 2 * JANELA_EM_MS),
      });
      return true;
    });
  } catch (erro) {
    logger.error('controle de frequencia do pre-teste falhou', erro);
    return true;
  }
}
