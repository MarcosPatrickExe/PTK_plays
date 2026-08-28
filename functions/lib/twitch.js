const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const crypto = require("crypto");
const { atualizarStatusPlataforma } = require("./postAoVivo");
const { registrarInicioTransmissao, registrarFimTransmissao } = require("./transmissoes");

const TWITCH_WEBHOOK_SECRET = defineSecret("TWITCH_WEBHOOK_SECRET");
const TWITCH_CLIENT_ID = defineSecret("TWITCH_CLIENT_ID");
const TWITCH_CLIENT_SECRET = defineSecret("TWITCH_CLIENT_SECRET");
const LOGIN_TWITCH = "patrickson_plays";

async function obterTokenDeApp(clientId, clientSecret) {
  const tokenResp = await fetch("https://id.twitch.tv/oauth2/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
      grant_type: "client_credentials",
    }),
  });
  if (!tokenResp.ok) {
    console.error("Falha ao obter token de app da Twitch:", tokenResp.status, await tokenResp.text());
    return null;
  }
  const { access_token: appToken } = await tokenResp.json();
  return appToken;
}

/**
 * O evento `stream.offline` do EventSub nao traz o VOD (nem o id da
 * transmissao que acabou de terminar). Busca o video mais recente do tipo
 * "archive" (VOD automatico da live) do canal via Helix - a live que
 * acabou de encerrar deve ser o primeiro resultado.
 */
async function buscarVodMaisRecente(broadcasterId, clientId, clientSecret) {
  const appToken = await obterTokenDeApp(clientId, clientSecret);
  if (!appToken) return null;

  const videosResp = await fetch(
    `https://api.twitch.tv/helix/videos?user_id=${broadcasterId}&type=archive&first=1`,
    { headers: { Authorization: `Bearer ${appToken}`, "Client-Id": clientId } },
  );
  if (!videosResp.ok) {
    console.error("Falha ao consultar VODs da Twitch:", videosResp.status, await videosResp.text());
    return null;
  }
  const { data } = await videosResp.json();
  const vod = data && data[0];
  if (!vod) return null;

  return { vodId: vod.id, vodUrl: vod.url };
}

/**
 * O evento `stream.online` nao traz titulo, jogo nem thumbnail (isso so vem
 * no `channel.update`/nao existe no evento, que nao assinamos) - busca via
 * Helix "Get Streams", que retorna esses dados de uma stream que esta ao
 * vivo agora.
 */
async function buscarDadosAoVivoTwitch(broadcasterId, clientId, clientSecret) {
  const appToken = await obterTokenDeApp(clientId, clientSecret);
  if (!appToken) return null;

  const streamsResp = await fetch(`https://api.twitch.tv/helix/streams?user_id=${broadcasterId}`, {
    headers: { Authorization: `Bearer ${appToken}`, "Client-Id": clientId },
  });
  if (!streamsResp.ok) {
    console.error("Falha ao consultar stream ao vivo da Twitch:", streamsResp.status, await streamsResp.text());
    return null;
  }
  const { data } = await streamsResp.json();
  const stream = data && data[0];
  if (!stream) return null;

  return {
    titulo: stream.title || null,
    jogo: stream.game_name || null,
    // thumbnail_url vem com placeholders literais {width}x{height} - a Twitch
    // documenta isso explicitamente, precisa substituir por um tamanho real.
    thumbnailUrl: stream.thumbnail_url
      ? stream.thumbnail_url.replace("{width}", "440").replace("{height}", "248")
      : null,
  };
}
exports.buscarDadosAoVivoTwitch = buscarDadosAoVivoTwitch;

function assinaturaValida(req, segredo) {
  const id = req.header("Twitch-Eventsub-Message-Id");
  const timestamp = req.header("Twitch-Eventsub-Message-Timestamp");
  const recebida = req.header("Twitch-Eventsub-Message-Signature");
  if (!id || !timestamp || !recebida) return false;

  try {
    const mensagem = id + timestamp + req.rawBody;
    const esperada = "sha256=" + crypto.createHmac("sha256", segredo).update(mensagem).digest("hex");
    return crypto.timingSafeEqual(Buffer.from(esperada), Buffer.from(recebida));
  } catch {
    return false;
  }
}

/**
 * Recebe os eventos EventSub da Twitch (stream.online / stream.offline) em
 * tempo real. A inscricao nesses eventos e feita uma unica vez, via o script
 * functions/scripts/setup-twitch-eventsub.js.
 */
exports.twitchWebhook = onRequest(
  { secrets: [TWITCH_WEBHOOK_SECRET, TWITCH_CLIENT_ID, TWITCH_CLIENT_SECRET], region: "southamerica-east1" },
  async (req, res) => {
    if (!assinaturaValida(req, TWITCH_WEBHOOK_SECRET.value())) {
      res.status(403).send("Assinatura invalida");
      return;
    }

    const tipoMensagem = req.header("Twitch-Eventsub-Message-Type");

    if (tipoMensagem === "webhook_callback_verification") {
      res.status(200).type("text/plain").send(req.body.challenge);
      return;
    }

    if (tipoMensagem === "notification") {
      const tipoEvento = req.body.subscription.type;
      if (tipoEvento === "stream.online") {
        const urlDaLive = `https://twitch.tv/${LOGIN_TWITCH}`;
        const dadosAoVivo = await buscarDadosAoVivoTwitch(
          req.body.event.broadcaster_user_id,
          TWITCH_CLIENT_ID.value(),
          TWITCH_CLIENT_SECRET.value(),
        );
        await atualizarStatusPlataforma("twitch", true, urlDaLive, dadosAoVivo || {});
        await registrarInicioTransmissao({
          plataforma: "twitch",
          idDaTransmissao: req.body.event.id,
          urlDaLive,
          titulo: dadosAoVivo && dadosAoVivo.titulo,
        });
      } else if (tipoEvento === "stream.offline") {
        const resultado = await atualizarStatusPlataforma("twitch", false, null);
        if (resultado.tipo === "encerrada") {
          const broadcasterId = req.body.event.broadcaster_user_id;
          await registrarFimTransmissao({
            plataforma: "twitch",
            resolverVod: () => buscarVodMaisRecente(broadcasterId, TWITCH_CLIENT_ID.value(), TWITCH_CLIENT_SECRET.value()),
          });
        }
      }
      res.status(200).send();
      return;
    }

    // revocation ou outro tipo de mensagem: so confirma recebimento
    res.status(200).send();
  },
);
