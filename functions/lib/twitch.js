const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const crypto = require("crypto");
const { atualizarStatusPlataforma } = require("./postAoVivo");

const TWITCH_WEBHOOK_SECRET = defineSecret("TWITCH_WEBHOOK_SECRET");
const LOGIN_TWITCH = "patrickson_plays";

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
exports.twitchWebhook = onRequest({ secrets: [TWITCH_WEBHOOK_SECRET], region: "southamerica-east1" }, async (req, res) => {
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
      await atualizarStatusPlataforma("twitch", true, `https://twitch.tv/${LOGIN_TWITCH}`);
    } else if (tipoEvento === "stream.offline") {
      await atualizarStatusPlataforma("twitch", false, null);
    }
    res.status(200).send();
    return;
  }

  // revocation ou outro tipo de mensagem: so confirma recebimento
  res.status(200).send();
});
