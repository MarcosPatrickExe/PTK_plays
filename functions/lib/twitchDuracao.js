/**
 * Converte a duracao no formato da Twitch (ex: "6h26m14s", "45m10s", "30s")
 * pra segundos. Usado so no backfill historico
 * (`scripts/backfill-transmissoes-passadas.js`) - a deteccao em tempo real
 * calcula a duracao a partir do inicio/fim que a gente mesmo detecta, nao
 * precisa parsear isso.
 */
function parseDuracaoTwitch(duracao) {
  if (!duracao) return null;
  const match = /^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?$/.exec(duracao);
  if (!match || !(match[1] || match[2] || match[3])) return null;

  const [, horas, minutos, segundos] = match;
  return (Number(horas) || 0) * 3600 + (Number(minutos) || 0) * 60 + (Number(segundos) || 0);
}

module.exports = { parseDuracaoTwitch };
