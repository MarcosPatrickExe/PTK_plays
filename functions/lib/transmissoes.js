const { Firestore } = require("@google-cloud/firestore");
const { getFirestore } = require("firebase-admin/firestore");

const PROJETO_STUDIO = "ptk-ai-studio";

// Application Default Credentials: a conta de servico das Functions
// (696548413882-compute@developer.gserviceaccount.com) recebeu
// `roles/datastore.user` nesse projeto pelo console do GCP - nao criamos
// nem baixamos chave de service account nenhuma.
const studio = new Firestore({ projectId: PROJETO_STUDIO });

/**
 * `${plataforma}_${idDaTransmissao}` - ID deterministico do documento em
 * `transmissoes`. Precisa ser estavel entre a escrita de inicio e a de fim
 * da mesma transmissao, e entre reexecucoes (a checagem agendada do
 * YouTube roda varias vezes durante a mesma live).
 */
function idDocumentoTransmissao(plataforma, idDaTransmissao) {
  return `${plataforma}_${idDaTransmissao}`;
}

function calcularDuracaoSegundos(iniciadaEmIso, agora = new Date()) {
  const diffMs = agora.getTime() - new Date(iniciadaEmIso).getTime();
  return Math.max(0, Math.round(diffMs / 1000));
}

// _privado/transmissoesAtivas/porPlataforma/{plataforma}, no Firestore do
// proprio ptk-plays (nao no ptk-ai-studio): guarda qual transmissao esta
// em andamento em cada plataforma. Necessario porque nem todo evento de
// "fim" traz o id da transmissao (o stream.offline da Twitch, por
// exemplo, so traz dados do broadcaster) - sem isso nao daria pra saber
// qual documento fechar em `transmissoes` nem calcular a duracao.
function refEstadoAtivo(plataforma) {
  return getFirestore()
    .collection("_privado")
    .doc("transmissoesAtivas")
    .collection("porPlataforma")
    .doc(plataforma);
}

/**
 * Registra o inicio de uma transmissao: grava o estado ativo (pra
 * localizar no fim) e o documento em `transmissoes` no ptk-ai-studio.
 * Com `merge: true` porque a checagem agendada do YouTube pode chamar
 * isso varias vezes pra mesma live sem duplicar nada.
 *
 * Se a plataforma nao expos um id de transmissao reconhecivel, nao
 * inventamos um - so avisamos no log e nao gravamos nada (nem estado
 * ativo, nem documento).
 */
async function registrarInicioTransmissao({ plataforma, idDaTransmissao, urlDaLive }) {
  if (!idDaTransmissao) {
    console.warn(`[transmissoes] inicio de "${plataforma}" sem idDaTransmissao reconhecido - nada gravado.`);
    return;
  }

  const agora = new Date();

  await refEstadoAtivo(plataforma).set({
    idDaTransmissao,
    iniciadaEm: agora.toISOString(),
  });

  await studio
    .collection("transmissoes")
    .doc(idDocumentoTransmissao(plataforma, idDaTransmissao))
    .set(
      {
        plataforma,
        iniciadaEm: agora,
        urlDaLive,
        idDaTransmissao,
        encerrada: false,
      },
      { merge: true },
    );
}

/**
 * Registra o fim de uma transmissao: le o estado ativo salvo no inicio
 * (pra saber qual documento fechar e calcular a duracao), chama
 * `resolverVod` (se fornecido) pra obter vodId/vodUrl, e atualiza o
 * documento em `transmissoes`.
 *
 * `resolverVod(idDaTransmissao)` deve retornar `{ vodId, vodUrl }` (campos
 * omitidos se a plataforma nao expuser o VOD) ou `undefined`/`null`.
 */
async function registrarFimTransmissao({ plataforma, resolverVod }) {
  const ref = refEstadoAtivo(plataforma);
  const snap = await ref.get();

  if (!snap.exists) {
    console.warn(`[transmissoes] fim de "${plataforma}" sem inicio registrado - nada pra encerrar.`);
    return;
  }

  const { idDaTransmissao, iniciadaEm } = snap.data();
  await ref.delete();

  const agora = new Date();
  const vod = resolverVod ? await resolverVod(idDaTransmissao) : null;

  await studio
    .collection("transmissoes")
    .doc(idDocumentoTransmissao(plataforma, idDaTransmissao))
    .set(
      {
        encerrada: true,
        encerradaEm: agora,
        duracaoSegundos: calcularDuracaoSegundos(iniciadaEm, agora),
        ...(vod && vod.vodId ? { vodId: vod.vodId } : {}),
        ...(vod && vod.vodUrl ? { vodUrl: vod.vodUrl } : {}),
      },
      { merge: true },
    );
}

module.exports = {
  idDocumentoTransmissao,
  calcularDuracaoSegundos,
  registrarInicioTransmissao,
  registrarFimTransmissao,
};
