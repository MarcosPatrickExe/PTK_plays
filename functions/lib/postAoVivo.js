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
 * Uma entrada de `linksPorPlataforma` esta ao vivo quando nao foi marcada
 * com `aoVivo: false`. O formato legado (o link gravado como texto puro,
 * usado antes dos dados extras existirem) conta como ao vivo - era o unico
 * jeito de uma entrada existir naquele formato.
 */
function estaAoVivo(dados) {
  if (typeof dados === "string") return true;
  return !!dados && dados.aoVivo !== false;
}

/**
 * Duracao em segundos entre o inicio da transmissao e `agora`. Aceita o
 * `iniciadaEm` do Firestore (Timestamp) e tambem Date/string, e devolve
 * `null` quando nao da pra calcular (entrada legada, sem esse campo) - o
 * card simplesmente nao mostra duracao nesse caso, em vez de mostrar zero.
 */
function calcularDuracaoSegundos(iniciadaEm, agora) {
  if (!iniciadaEm) return null;
  const inicio = typeof iniciadaEm.toDate === "function" ? iniciadaEm.toDate() : new Date(iniciadaEm);
  if (Number.isNaN(inicio.getTime())) return null;
  return Math.max(0, Math.round((agora.getTime() - inicio.getTime()) / 1000));
}

/**
 * Cria ou atualiza o post "ao vivo" ativo (tipo aoVivo, encerrada == false) de
 * acordo com a mudanca de status de uma plataforma. Roda dentro de uma
 * transacao pra evitar corrida entre o polling do YouTube e os webhooks da
 * Twitch/Kick escrevendo ao mesmo tempo.
 *
 * @param {"youtube"|"twitch"|"kick"} plataforma
 * @param {boolean} aoVivo true quando a plataforma acabou de ficar ao vivo, false quando saiu do ar
 * @param {string|null} link url da live (so usado quando aoVivo == true)
 * @param {{titulo?: string|null, jogo?: string|null, thumbnailUrl?: string|null}} [detalhes]
 *   dados extras da live pra exibir no card do Feed (so usado quando aoVivo == true).
 *   Campos ausentes/nulos simplesmente nao sao gravados.
 */
async function atualizarStatusPlataforma(plataforma, aoVivo, link, detalhes) {
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
      const { titulo, jogo, thumbnailUrl } = detalhes || {};
      const dadosPlataforma = {
        link,
        iniciadaEm: FieldValue.serverTimestamp(),
        ...(titulo ? { titulo } : {}),
        ...(jogo ? { jogo } : {}),
        ...(thumbnailUrl ? { thumbnailUrl } : {}),
      };

      dadosPlataforma.aoVivo = true;

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
          linksPorPlataforma: { [plataforma]: dadosPlataforma },
          encerrada: false,
        });
        return { tipo: "semNotificacao" }; // onDocumentCreated ja cuida da notificacao
      }

      const linksAtuais = postAtivo.data().linksPorPlataforma || {};
      const dadosAtuais = linksAtuais[plataforma];
      // So e "sem mudanca" se a plataforma ja estiver ao vivo com esse
      // mesmo link. Uma plataforma que ja encerrou (aoVivo: false) e voltou
      // conta como nova: a entrada e reescrita do zero, com iniciadaEm novo.
      const jaAoVivo = estaAoVivo(dadosAtuais);
      if (jaAoVivo && dadosAtuais.link === link) {
        return { tipo: "semMudanca" };
      }

      const eraNovaPlataforma = !jaAoVivo;
      tx.update(postAtivo.ref, { [`linksPorPlataforma.${plataforma}`]: dadosPlataforma });
      return eraNovaPlataforma
        ? { tipo: "novaPlataforma", postId: postAtivo.id, plataforma }
        : { tipo: "semMudanca" };
    }

    // aoVivo == false: encerra a plataforma no post ativo, se existir.
    if (!postAtivo) return { tipo: "semMudanca" };

    const linksAtuais = postAtivo.data().linksPorPlataforma || {};
    const dadosAtuais = linksAtuais[plataforma];
    if (!dadosAtuais || estaAoVivo(dadosAtuais) === false) return { tipo: "semMudanca" };

    // Os dados da plataforma NAO sao apagados aqui (era `FieldValue.delete()`
    // antes): o card do Feed continua mostrando jogo, plataforma, duracao e
    // data de encerramento depois que a live acaba. Quem some do ar e
    // marcado com `aoVivo: false`.
    const agora = new Date();
    const duracaoSegundos = calcularDuracaoSegundos(dadosAtuais.iniciadaEm, agora);

    const aindaAoVivo = Object.entries(linksAtuais).some(
      ([nome, dados]) => nome !== plataforma && estaAoVivo(dados),
    );

    tx.update(postAtivo.ref, {
      [`linksPorPlataforma.${plataforma}.aoVivo`]: false,
      [`linksPorPlataforma.${plataforma}.encerradaEm`]: agora,
      ...(duracaoSegundos != null ? { [`linksPorPlataforma.${plataforma}.duracaoSegundos`]: duracaoSegundos } : {}),
      ...(aindaAoVivo ? {} : { encerrada: true }),
    });
    return { tipo: "encerrada", postId: postAtivo.id };
  });

  if (resultado.tipo === "novaPlataforma") {
    await notificarNovaPlataforma(resultado.postId, resultado.plataforma);
  }

  return resultado;
}

/**
 * Anexa o link da gravacao (VOD) a plataforma dentro do post do Feed, pra
 * que o card continue clicavel depois que a live acaba - o toque leva pra
 * gravacao em vez de um link de live que nao existe mais.
 *
 * Roda depois de `atualizarStatusPlataforma(..., false, ...)` porque o VOD
 * so e resolvido apos o fim (a Twitch precisa de uma chamada a Helix).
 * Silencioso quando nao ha VOD (a Kick nao expoe um).
 */
async function anexarVodAoPost({ postId, plataforma, vodUrl }) {
  if (!postId || !vodUrl) return;
  await getFirestore()
    .collection("posts")
    .doc(postId)
    .update({ [`linksPorPlataforma.${plataforma}.vodUrl`]: vodUrl });
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

module.exports = { atualizarStatusPlataforma, anexarVodAoPost, estaAoVivo, calcularDuracaoSegundos };
