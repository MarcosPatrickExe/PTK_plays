#!/usr/bin/env node
/**
 * Script de backfill (roda uma vez, manualmente): busca o historico de
 * lives passadas do YouTube e da Twitch e grava retroativamente em
 * `transmissoes` no Firestore do ptk-ai-studio, com o mesmo formato que
 * `functions/lib/transmissoes.js` usa pra deteccao em tempo real (id
 * deterministico `${plataforma}_${idDaTransmissao}`, merge:true - seguro
 * rodar de novo sem duplicar nada).
 *
 * A Kick fica de fora: a API publica dela (docs.kick.com) nao documenta
 * nenhum endpoint pra listar videos/VODs passados do canal - so o webhook
 * de evento em tempo real (ja coberto por `functions/lib/kick.js`). Se a
 * Kick lancar isso no futuro, da pra estender este script.
 *
 * Uso: node functions/scripts/backfill-transmissoes-passadas.js
 *
 * Pre-requisito de credenciais: como isso e um script avulso (nao uma
 * Function implantada), ele NAO herda a identidade da conta de servico
 * das Functions automaticamente. A forma mais simples de autenticar e
 * `gcloud auth application-default login` com a sua propria conta Google
 * - como voce e dono (Owner) do projeto ptk-ai-studio, isso ja basta pras
 * Application Default Credentials terem acesso de escrita no Firestore de
 * la, sem precisar criar chave de service account nem conceder nenhuma
 * role adicional.
 */
const { execSync } = require("child_process");
const { Firestore } = require("@google-cloud/firestore");
const { parseDuracaoTwitch } = require("../lib/twitchDuracao");

const PROJETO_PTK_PLAYS = "ptk-plays";
const CANAL_ID_YOUTUBE = "UCB0Xu_75SQQIHVjaTmGBYuQ";
const LOGIN_TWITCH = "patrickson_plays";

const studio = new Firestore({ projectId: "ptk-ai-studio" });

function lerSecret(nome) {
  return execSync(`firebase functions:secrets:access ${nome} --project ${PROJETO_PTK_PLAYS}`, {
    encoding: "utf8",
  }).trim();
}

function idDocumentoTransmissao(plataforma, idDaTransmissao) {
  return `${plataforma}_${idDaTransmissao}`;
}

async function gravarTransmissaoPassada(doc) {
  await studio
    .collection("transmissoes")
    .doc(idDocumentoTransmissao(doc.plataforma, doc.idDaTransmissao))
    .set(doc, { merge: true });
  console.log(`  gravado: ${doc.plataforma}_${doc.idDaTransmissao} - "${doc.titulo || "(sem titulo)"}"`);
}

// ---------- YouTube ----------
// Estrategia barata em cota: em vez de search.list (100 unidades/chamada),
// pega a playlist de uploads do canal (1 unidade) e pagina playlistItems
// (1 unidade/pagina de 50), depois confere em lote (videos.list, 1
// unidade/lote de ate 50 ids) quais desses videos tem liveStreamingDetails
// preenchido - so esses foram lives de verdade.

async function backfillYoutube(apiKey) {
  console.log("\n== YouTube ==");

  const canalResp = await fetch(
    `https://www.googleapis.com/youtube/v3/channels?part=contentDetails&id=${CANAL_ID_YOUTUBE}&key=${apiKey}`,
  );
  const canalDados = await canalResp.json();
  const uploadsPlaylistId = canalDados.items?.[0]?.contentDetails?.relatedPlaylists?.uploads;
  if (!uploadsPlaylistId) {
    console.error("Nao encontrei a playlist de uploads do canal:", canalDados);
    return;
  }

  const videoIds = [];
  let pageToken = "";
  do {
    const url = new URL("https://www.googleapis.com/youtube/v3/playlistItems");
    url.searchParams.set("part", "contentDetails");
    url.searchParams.set("playlistId", uploadsPlaylistId);
    url.searchParams.set("maxResults", "50");
    url.searchParams.set("key", apiKey);
    if (pageToken) url.searchParams.set("pageToken", pageToken);

    const resp = await fetch(url);
    const dados = await resp.json();
    for (const item of dados.items || []) {
      videoIds.push(item.contentDetails.videoId);
    }
    pageToken = dados.nextPageToken || "";
  } while (pageToken);

  console.log(`${videoIds.length} videos no canal - checando quais foram lives...`);

  let totalLives = 0;
  for (let i = 0; i < videoIds.length; i += 50) {
    const lote = videoIds.slice(i, i + 50);
    const url = new URL("https://www.googleapis.com/youtube/v3/videos");
    url.searchParams.set("part", "snippet,liveStreamingDetails");
    url.searchParams.set("id", lote.join(","));
    url.searchParams.set("key", apiKey);

    const resp = await fetch(url);
    const dados = await resp.json();

    for (const item of dados.items || []) {
      const detalhes = item.liveStreamingDetails;
      // sem liveStreamingDetails = video normal, nunca foi live. Sem
      // actualEndTime = e uma live que ainda esta ao vivo agora (nao e
      // "passada" ainda, a Function de deteccao em tempo real cuida dela).
      if (!detalhes || !detalhes.actualStartTime || !detalhes.actualEndTime) continue;

      const inicio = new Date(detalhes.actualStartTime);
      const fim = new Date(detalhes.actualEndTime);
      const urlDaLive = `https://www.youtube.com/watch?v=${item.id}`;

      await gravarTransmissaoPassada({
        plataforma: "youtube",
        idDaTransmissao: item.id,
        titulo: item.snippet?.title,
        urlDaLive,
        iniciadaEm: inicio,
        encerrada: true,
        encerradaEm: fim,
        duracaoSegundos: Math.round((fim.getTime() - inicio.getTime()) / 1000),
        vodId: item.id,
        vodUrl: urlDaLive,
      });
      totalLives++;
    }
  }

  console.log(`${totalLives} lives passadas gravadas do YouTube.`);
}

// ---------- Twitch ----------

async function obterTokenDeAppTwitch(clientId, clientSecret) {
  const resp = await fetch("https://id.twitch.tv/oauth2/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ client_id: clientId, client_secret: clientSecret, grant_type: "client_credentials" }),
  });
  const dados = await resp.json();
  if (!resp.ok) {
    console.error("Falha ao obter token de app da Twitch:", resp.status, dados);
    process.exit(1);
  }
  return dados.access_token;
}

async function backfillTwitch(clientId, clientSecret) {
  console.log("\n== Twitch ==");
  const appToken = await obterTokenDeAppTwitch(clientId, clientSecret);
  const headers = { Authorization: `Bearer ${appToken}`, "Client-Id": clientId };

  const userResp = await fetch(`https://api.twitch.tv/helix/users?login=${LOGIN_TWITCH}`, { headers });
  const userDados = await userResp.json();
  const broadcasterId = userDados.data?.[0]?.id;
  if (!broadcasterId) {
    console.error("Canal nao encontrado na Twitch:", userDados);
    return;
  }

  let cursor = "";
  let total = 0;
  do {
    const url = new URL("https://api.twitch.tv/helix/videos");
    url.searchParams.set("user_id", broadcasterId);
    url.searchParams.set("type", "archive");
    url.searchParams.set("first", "100");
    if (cursor) url.searchParams.set("after", cursor);

    const resp = await fetch(url, { headers });
    const dados = await resp.json();

    for (const vod of dados.data || []) {
      const inicio = new Date(vod.created_at);
      const duracaoSegundos = parseDuracaoTwitch(vod.duration);
      const fim = duracaoSegundos != null ? new Date(inicio.getTime() + duracaoSegundos * 1000) : null;

      await gravarTransmissaoPassada({
        plataforma: "twitch",
        // O `Get Videos` da Helix so devolve o id do VOD (vod.id) - um
        // espaco de id DIFERENTE do id de stream que a deteccao em tempo
        // real usa (event.id do stream.online). Nao da pra recuperar o id
        // de stream original de uma live passada por essa API, entao usar
        // vod.id aqui e intencional: o documento gerado pelo backfill fica
        // "congelado", sem tentativa de bater com o que a Function ao vivo
        // grave dali pra frente (se tentassemos casar os dois espacos de
        // id sem uma garantia real de equivalencia, o risco seria pior -
        // uma duplicata silenciosa por acreditar numa fusao que nao
        // acontece). So faz diferenca se essa MESMA live acabar sendo
        // processada tambem pela deteccao ao vivo (ela cria um segundo
        // documento, com o id de stream) - inofensivo pra dados passados.
        idDaTransmissao: vod.id,
        titulo: vod.title,
        urlDaLive: `https://twitch.tv/${LOGIN_TWITCH}`,
        iniciadaEm: inicio,
        encerrada: true,
        ...(fim ? { encerradaEm: fim } : {}),
        ...(duracaoSegundos != null ? { duracaoSegundos } : {}),
        vodId: vod.id,
        vodUrl: vod.url,
      });
      total++;
    }

    cursor = dados.pagination?.cursor || "";
  } while (cursor);

  console.log(`${total} VODs processados da Twitch.`);
}

async function main() {
  const youtubeApiKey = lerSecret("YOUTUBE_API_KEY");
  const twitchClientId = lerSecret("TWITCH_CLIENT_ID");
  const twitchClientSecret = lerSecret("TWITCH_CLIENT_SECRET");

  await backfillYoutube(youtubeApiKey);
  await backfillTwitch(twitchClientId, twitchClientSecret);

  console.log("\nBackfill concluido. A Kick nao foi incluida (sem API oficial pra historico - ver comentario no topo do arquivo).");
}

main();
