#!/usr/bin/env node
/**
 * Script de configuracao unica: cria as inscricoes EventSub da Twitch
 * (stream.online / stream.offline) apontando pra function twitchWebhook ja
 * deployada. So precisa rodar de novo se as inscricoes forem revogadas.
 *
 * Uso: node functions/scripts/setup-twitch-eventsub.js
 */
const { execSync } = require("child_process");

const CALLBACK_URL = "https://southamerica-east1-ptk-plays.cloudfunctions.net/twitchWebhook";
const LOGIN_TWITCH = "patrickson_plays";
const PROJETO = "ptk-plays";

function lerSecret(nome) {
  return execSync(`firebase functions:secrets:access ${nome} --project ${PROJETO}`, { encoding: "utf8" }).trim();
}

async function main() {
  const clientId = lerSecret("TWITCH_CLIENT_ID");
  const clientSecret = lerSecret("TWITCH_CLIENT_SECRET");
  const webhookSecret = lerSecret("TWITCH_WEBHOOK_SECRET");

  const tokenResp = await fetch("https://id.twitch.tv/oauth2/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
      grant_type: "client_credentials",
    }),
  });
  const tokenDados = await tokenResp.json();
  if (!tokenResp.ok) {
    console.error("Falha ao obter token de app:", tokenResp.status, tokenDados);
    process.exit(1);
  }
  const appToken = tokenDados.access_token;

  const userResp = await fetch(`https://api.twitch.tv/helix/users?login=${LOGIN_TWITCH}`, {
    headers: { Authorization: `Bearer ${appToken}`, "Client-Id": clientId },
  });
  const userDados = await userResp.json();
  const broadcasterId = userDados.data && userDados.data[0] && userDados.data[0].id;
  if (!broadcasterId) {
    console.error("Canal nao encontrado na Twitch:", userDados);
    process.exit(1);
  }
  console.log(`Broadcaster ID encontrado: ${broadcasterId}`);

  for (const tipo of ["stream.online", "stream.offline"]) {
    const resp = await fetch("https://api.twitch.tv/helix/eventsub/subscriptions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${appToken}`,
        "Client-Id": clientId,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        type: tipo,
        version: "1",
        condition: { broadcaster_user_id: broadcasterId },
        transport: { method: "webhook", callback: CALLBACK_URL, secret: webhookSecret },
      }),
    });
    const dados = await resp.json();
    if (resp.ok) {
      console.log(`Inscricao "${tipo}" criada (status: ${dados.data[0].status}).`);
    } else {
      console.error(`Falha ao criar inscricao "${tipo}":`, resp.status, dados);
    }
  }
}

main();
