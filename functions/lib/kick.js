const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const crypto = require("crypto");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { atualizarStatusPlataforma } = require("./postAoVivo");

const KICK_CLIENT_ID = defineSecret("KICK_CLIENT_ID");
const KICK_CLIENT_SECRET = defineSecret("KICK_CLIENT_SECRET");
const SLUG_KICK = "patrickson_plays";
const REDIRECT_URI = "https://southamerica-east1-ptk-plays.cloudfunctions.net/kickOAuthCallback";
const CHAVE_PUBLICA_URL = "https://api.kick.com/public/v1/public-key";

let chavePublicaCache = null;

async function obterChavePublicaKick() {
  if (chavePublicaCache) return chavePublicaCache;
  const resp = await fetch(CHAVE_PUBLICA_URL);
  const dados = await resp.json();
  chavePublicaCache = dados.data.public_key;
  return chavePublicaCache;
}

function assinaturaValida(mensagemId, timestamp, rawBody, assinaturaBase64, chavePublica) {
  const mensagem = `${mensagemId}.${timestamp}.${rawBody}`;
  const verificador = crypto.createVerify("RSA-SHA256");
  verificador.update(mensagem);
  verificador.end();
  return verificador.verify(chavePublica, assinaturaBase64, "base64");
}

/**
 * Recebe o evento "livestream.status.updated" da Kick em tempo real. A
 * entrega so comeca a funcionar depois da autorizacao unica feita em
 * /kickAuthStart (o app precisa do consentimento do dono do canal).
 */
exports.kickWebhook = onRequest({ region: "southamerica-east1" }, async (req, res) => {
  const mensagemId = req.header("Kick-Event-Message-Id");
  const timestamp = req.header("Kick-Event-Message-Timestamp");
  const assinatura = req.header("Kick-Event-Signature");
  const tipoEvento = req.header("Kick-Event-Type");

  if (!mensagemId || !timestamp || !assinatura) {
    res.status(400).send("Cabecalhos ausentes");
    return;
  }

  try {
    const chavePublica = await obterChavePublicaKick();
    const valido = assinaturaValida(mensagemId, timestamp, req.rawBody, assinatura, chavePublica);
    if (!valido) {
      res.status(403).send("Assinatura invalida");
      return;
    }
  } catch (e) {
    console.error("Erro verificando assinatura da Kick:", e);
    res.status(403).send("Assinatura invalida");
    return;
  }

  if (tipoEvento === "livestream.status.updated") {
    const aoVivo = !!req.body.is_live;
    await atualizarStatusPlataforma("kick", aoVivo, aoVivo ? `https://kick.com/${SLUG_KICK}` : null);
  }

  res.status(200).send();
});

function base64url(buffer) {
  return buffer.toString("base64").replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

/**
 * Passo 1 da autorizacao unica: gera o par PKCE, guarda o verifier num
 * documento temporario e redireciona pra tela de login/consentimento da
 * Kick. So precisa ser visitado uma vez (o dono do canal clica e aprova).
 */
exports.kickAuthStart = onRequest({ secrets: [KICK_CLIENT_ID], region: "southamerica-east1" }, async (req, res) => {
  const verifier = base64url(crypto.randomBytes(32));
  const challenge = base64url(crypto.createHash("sha256").update(verifier).digest());
  const state = base64url(crypto.randomBytes(16));

  await getFirestore().collection("_privado").doc("kickPkce").collection("estados").doc(state).set({
    verifier,
    criadoEm: FieldValue.serverTimestamp(),
  });

  const url = new URL("https://id.kick.com/oauth/authorize");
  url.searchParams.set("client_id", KICK_CLIENT_ID.value());
  url.searchParams.set("response_type", "code");
  url.searchParams.set("redirect_uri", REDIRECT_URI);
  url.searchParams.set("state", state);
  url.searchParams.set("scope", "channel:read events:subscribe");
  url.searchParams.set("code_challenge", challenge);
  url.searchParams.set("code_challenge_method", "S256");

  res.redirect(url.toString());
});

/**
 * Passo 2: recebe o retorno da Kick com o "code", troca por um token de
 * acesso e guarda o resultado em _privado/kickAuth (colecao bloqueada pras
 * regras do Firestore, so acessivel pelo Admin SDK).
 */
exports.kickOAuthCallback = onRequest(
  { secrets: [KICK_CLIENT_ID, KICK_CLIENT_SECRET], region: "southamerica-east1" },
  async (req, res) => {
    const { code, state } = req.query;
    if (!code || !state) {
      res.status(400).send("Faltou code ou state na resposta da Kick.");
      return;
    }

    const estadoRef = getFirestore().collection("_privado").doc("kickPkce").collection("estados").doc(String(state));
    const estadoSnap = await estadoRef.get();
    if (!estadoSnap.exists) {
      res.status(400).send("State invalido ou expirado. Tente autorizar de novo.");
      return;
    }
    const { verifier } = estadoSnap.data();
    await estadoRef.delete();

    const tokenResp = await fetch("https://id.kick.com/oauth/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "authorization_code",
        code: String(code),
        client_id: KICK_CLIENT_ID.value(),
        client_secret: KICK_CLIENT_SECRET.value(),
        redirect_uri: REDIRECT_URI,
        code_verifier: verifier,
      }),
    });

    const tokenDados = await tokenResp.json();
    if (!tokenResp.ok) {
      console.error("Falha ao trocar code por token na Kick:", tokenResp.status, tokenDados);
      res.status(500).send("Falha ao autorizar com a Kick. Veja os logs da function.");
      return;
    }

    await getFirestore().collection("_privado").doc("kickAuth").set({
      accessToken: tokenDados.access_token,
      refreshToken: tokenDados.refresh_token,
      expiresEm: Date.now() + tokenDados.expires_in * 1000,
      atualizadoEm: FieldValue.serverTimestamp(),
    });

    res.status(200).type("text/html").send("<h2>Autorizado! Pode fechar essa aba.</h2>");
  }
);
