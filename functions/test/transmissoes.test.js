const { idDocumentoTransmissao, calcularDuracaoSegundos } = require('../lib/transmissoes');

describe('idDocumentoTransmissao', () => {
  test('monta o id deterministico ${plataforma}_${idDaTransmissao}', () => {
    expect(idDocumentoTransmissao('youtube', 'abc123')).toBe('youtube_abc123');
    expect(idDocumentoTransmissao('twitch', '999')).toBe('twitch_999');
  });
});

describe('calcularDuracaoSegundos', () => {
  test('calcula a diferenca em segundos entre inicio e fim', () => {
    const inicio = '2026-01-01T10:00:00.000Z';
    const fim = new Date('2026-01-01T10:05:30.000Z');
    expect(calcularDuracaoSegundos(inicio, fim)).toBe(330);
  });

  test('nunca retorna negativo (fim antes do inicio por relogio/latencia)', () => {
    const inicio = '2026-01-01T10:05:00.000Z';
    const fim = new Date('2026-01-01T10:00:00.000Z');
    expect(calcularDuracaoSegundos(inicio, fim)).toBe(0);
  });
});

// registrarInicioTransmissao/registrarFimTransmissao (as duas funcoes que
// de fato leem/escrevem no Firestore) nao tem teste automatizado aqui: elas
// dependem de Application Default Credentials reais pro projeto
// `ptk-ai-studio` e de um app do firebase-admin inicializado (`getFirestore()`
// do documento de estado em `ptk-plays`) - nenhum dos dois esta disponivel
// neste sandbox (sem gcloud/firebase autenticados, sem emulador rodando).
// So a logica pura (id deterministico e calculo de duracao) e testada.
