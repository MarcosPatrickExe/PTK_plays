const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const { atualizarStatusPlataforma } = require("./postAoVivo");

const YOUTUBE_API_KEY = defineSecret("YOUTUBE_API_KEY");
const CANAL_ID = "UCB0Xu_75SQQIHVjaTmGBYuQ";

/**
 * So o YouTube precisa de polling: a API deles nao oferece um jeito barato de
 * "escutar" quando um canal qualquer fica ao vivo (ao contrario da Twitch e da
 * Kick, que avisam via webhook). Roda so sabado/domingo, 13h-22h30 (Brasilia),
 * a cada 30min, pra ficar bem longe da cota gratuita de 10.000 unidades/dia
 * (20 checagens/dia x 100 unidades = 2.000/dia).
 */
exports.verificarYoutubeAoVivo = onSchedule(
  {
    schedule: "0,30 13-22 * * 6,0",
    timeZone: "America/Sao_Paulo",
    region: "southamerica-east1",
    secrets: [YOUTUBE_API_KEY],
  },
  async () => {
    const url = new URL("https://www.googleapis.com/youtube/v3/search");
    url.searchParams.set("part", "snippet");
    url.searchParams.set("channelId", CANAL_ID);
    url.searchParams.set("eventType", "live");
    url.searchParams.set("type", "video");
    url.searchParams.set("key", YOUTUBE_API_KEY.value());

    const resp = await fetch(url);
    if (!resp.ok) {
      console.error("Falha ao consultar a API do YouTube:", resp.status, await resp.text());
      return;
    }

    const dados = await resp.json();
    const item = dados.items && dados.items[0];

    if (item && item.id && item.id.videoId) {
      await atualizarStatusPlataforma("youtube", true, `https://www.youtube.com/watch?v=${item.id.videoId}`);
    } else {
      await atualizarStatusPlataforma("youtube", false, null);
    }
  }
);
