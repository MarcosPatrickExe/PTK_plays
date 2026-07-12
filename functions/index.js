const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

// Mesma regiao do Firestore (Sao Paulo), pra manter tudo perto.
setGlobalOptions({ region: "southamerica-east1" });

const TOPICO_AO_VIVO = "ao_vivo";

/**
 * Dispara quando um post novo e criado em `posts/{postId}`. Se for do tipo
 * "aoVivo", manda uma notificacao push pro topico `ao_vivo` (todo app
 * inscrito nesse topico recebe). O data.postId vai junto pra o app saber
 * pra qual card do Feed rolar quando o usuario tocar na notificacao.
 */
exports.notificarAoVivo = onDocumentCreated("posts/{postId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const post = snapshot.data();
  if (!post || post.tipo !== "aoVivo") return;

  const corpo = post.texto || "Corre pra assistir agora!";

  await getMessaging().send({
    topic: TOPICO_AO_VIVO,
    notification: {
      title: "PTK Plays está AO VIVO! 🔴",
      body: corpo,
    },
    data: {
      postId: event.params.postId,
      tipo: "aoVivo",
    },
    android: {
      priority: "high",
      notification: { sound: "default" },
    },
    apns: {
      payload: {
        aps: { sound: "default" },
      },
    },
  });
});
