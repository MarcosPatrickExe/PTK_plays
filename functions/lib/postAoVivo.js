const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

const AUTOR_NICKNAME_AO_VIVO = "PTK Plays";
const TOPICO_AO_VIVO = "ao_vivo";

const LABELS_PLATAFORMA = {
  youtube: "YouTube",
  twitch: "Twitch",
  kick: "Kick",
};

/**
 * Cria ou atualiza o post "ao vivo" ativo (tipo aoVivo, encerrada == false) de
 * acordo com a mudanca de status de uma plataforma. Roda dentro de uma
 * transacao pra evitar corrida entre o polling do YouTube e os webhooks da
 * Twitch/Kick escrevendo ao mesmo tempo.
 *
 * @param {"youtube"|"twitch"|"kick"} plataforma
 * @param {boolean} aoVivo true quando a plataforma acabou de ficar ao vivo, false quando saiu do ar
 * @param {string|null} link url da live (so usado quando aoVivo == true)
 */
async function atualizarStatusPlataforma(plataforma, aoVivo, link) {
  const db = getFirestore();
  const postsRef = db.collection("posts");

  const resultado = await db.runTransaction(async (tx) => {
    const query = postsRef
      .where("tipo", "==", "aoVivo")
      .where("encerrada", "==", false)
      .orderBy("criadoEm", "desc")
      .limit(1);
    const snap = await tx.get(query);
    const postAtivo = snap.empty ? null : snap.docs[0];

    if (aoVivo) {
      if (!postAtivo) {
        const novoRef = postsRef.doc();
        tx.set(novoRef, {
          tipo: "aoVivo",
          autorUid: "sistema",
          autorNickname: AUTOR_NICKNAME_AO_VIVO,
          criadoEm: FieldValue.serverTimestamp(),
          curtidas: 0,
          comentariosCount: 0,
          texto: "Corre pra assistir agora!",
          linksPorPlataforma: { [plataforma]: link },
          encerrada: false,
        });
        return { tipo: "semNotificacao" }; // onDocumentCreated ja cuida da notificacao
      }

      const linksAtuais = postAtivo.data().linksPorPlataforma || {};
      if (linksAtuais[plataforma] === link) {
        return { tipo: "semMudanca" };
      }

      const eraNovaPlataforma = !linksAtuais[plataforma];
      tx.update(postAtivo.ref, { [`linksPorPlataforma.${plataforma}`]: link });
      return eraNovaPlataforma
        ? { tipo: "novaPlataforma", postId: postAtivo.id, plataforma }
        : { tipo: "semMudanca" };
    }

    // aoVivo == false: encerra a plataforma no post ativo, se existir
    if (!postAtivo) return { tipo: "semMudanca" };

    const linksAtuais = postAtivo.data().linksPorPlataforma || {};
    if (!linksAtuais[plataforma]) return { tipo: "semMudanca" };

    const restantes = { ...linksAtuais };
    delete restantes[plataforma];
    const encerrouTudo = Object.keys(restantes).length === 0;

    tx.update(postAtivo.ref, {
      [`linksPorPlataforma.${plataforma}`]: FieldValue.delete(),
      ...(encerrouTudo ? { encerrada: true } : {}),
    });
    return { tipo: "encerrada" };
  });

  if (resultado.tipo === "novaPlataforma") {
    await notificarNovaPlataforma(resultado.postId, resultado.plataforma);
  }

  return resultado;
}

async function notificarNovaPlataforma(postId, plataforma) {
  const label = LABELS_PLATAFORMA[plataforma] || plataforma;
  await getMessaging().send({
    topic: TOPICO_AO_VIVO,
    notification: {
      title: "PTK Plays está AO VIVO! 🔴",
      body: `Agora também ao vivo na ${label}!`,
    },
    data: { postId, tipo: "aoVivo" },
    android: { priority: "high", notification: { sound: "default" } },
    apns: { payload: { aps: { sound: "default" } } },
  });
}

module.exports = { atualizarStatusPlataforma };
