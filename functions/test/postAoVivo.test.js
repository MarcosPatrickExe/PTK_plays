const SERVER_TIMESTAMP = 'SERVER_TIMESTAMP';
const FIELD_DELETE = 'FIELD_DELETE';

let postAtivoSnap = { empty: true, docs: [] };
const mockTxGet = jest.fn().mockImplementation(async () => postAtivoSnap);
const mockTxSet = jest.fn();
const mockTxUpdate = jest.fn();

const mockRunTransaction = jest.fn().mockImplementation(async (callback) => {
  return callback({ get: mockTxGet, set: mockTxSet, update: mockTxUpdate });
});

const mockNovoDocRef = { id: 'novo-post-id' };
const mockPostsRef = {
  where: jest.fn().mockReturnThis(),
  orderBy: jest.fn().mockReturnThis(),
  limit: jest.fn().mockReturnThis(),
  doc: jest.fn().mockReturnValue(mockNovoDocRef),
};

jest.mock('firebase-admin/firestore', () => ({
  getFirestore: () => ({
    collection: () => mockPostsRef,
    runTransaction: (callback) => mockRunTransaction(callback),
  }),
  FieldValue: {
    serverTimestamp: () => SERVER_TIMESTAMP,
    delete: () => FIELD_DELETE,
  },
}));

const mockMessagingSend = jest.fn().mockResolvedValue(undefined);
jest.mock('firebase-admin/messaging', () => ({
  getMessaging: () => ({ send: (...args) => mockMessagingSend(...args) }),
}));

const { atualizarStatusPlataforma } = require('../lib/postAoVivo');

const REF_POST_EXISTENTE = { id: 'ref-post-existente' };

function postComPlataformas(linksPorPlataforma) {
  return {
    empty: false,
    docs: [{ id: 'post-existente', ref: REF_POST_EXISTENTE, data: () => ({ linksPorPlataforma }) }],
  };
}

describe('atualizarStatusPlataforma', () => {
  beforeEach(() => {
    postAtivoSnap = { empty: true, docs: [] };
    mockTxGet.mockClear();
    mockTxSet.mockClear();
    mockTxUpdate.mockClear();
    mockRunTransaction.mockClear();
    mockMessagingSend.mockClear();
  });

  test('cria um post novo com link, iniciadaEm e os detalhes extras (titulo/jogo/thumbnailUrl) quando nao ha post ativo', async () => {
    await atualizarStatusPlataforma('twitch', true, 'https://twitch.tv/patrickson_plays', {
      titulo: 'Rankeada até de madrugada',
      jogo: 'Valorant',
      thumbnailUrl: 'https://static-cdn.jtvnw.net/preview.jpg',
    });

    expect(mockTxSet).toHaveBeenCalledTimes(1);
    const [, dados] = mockTxSet.mock.calls[0];
    expect(dados.linksPorPlataforma.twitch).toEqual({
      link: 'https://twitch.tv/patrickson_plays',
      iniciadaEm: SERVER_TIMESTAMP,
      titulo: 'Rankeada até de madrugada',
      jogo: 'Valorant',
      thumbnailUrl: 'https://static-cdn.jtvnw.net/preview.jpg',
    });
  });

  test('nao grava titulo/jogo/thumbnailUrl quando a plataforma nao os fornece (ex: Kick sem categoria)', async () => {
    await atualizarStatusPlataforma('kick', true, 'https://kick.com/patrickson_plays', { titulo: 'Só de boa' });

    const [, dados] = mockTxSet.mock.calls[0];
    expect(dados.linksPorPlataforma.kick).toEqual({
      link: 'https://kick.com/patrickson_plays',
      iniciadaEm: SERVER_TIMESTAMP,
      titulo: 'Só de boa',
    });
  });

  test('adiciona uma nova plataforma a um post ja ativo e dispara a notificacao', async () => {
    postAtivoSnap = postComPlataformas({
      youtube: { link: 'https://youtube.com/watch?v=abc', iniciadaEm: SERVER_TIMESTAMP },
    });

    await atualizarStatusPlataforma('twitch', true, 'https://twitch.tv/patrickson_plays', { jogo: 'Valorant' });

    expect(mockTxUpdate).toHaveBeenCalledWith(REF_POST_EXISTENTE, {
      'linksPorPlataforma.twitch': {
        link: 'https://twitch.tv/patrickson_plays',
        iniciadaEm: SERVER_TIMESTAMP,
        jogo: 'Valorant',
      },
    });
    expect(mockMessagingSend).toHaveBeenCalledTimes(1);
  });

  test('nao faz nada (sem update, sem notificacao) quando a mesma plataforma reenvia o mesmo link', async () => {
    postAtivoSnap = postComPlataformas({
      twitch: { link: 'https://twitch.tv/patrickson_plays', iniciadaEm: SERVER_TIMESTAMP, jogo: 'Valorant' },
    });

    await atualizarStatusPlataforma('twitch', true, 'https://twitch.tv/patrickson_plays', { jogo: 'Valorant' });

    expect(mockTxUpdate).not.toHaveBeenCalled();
    expect(mockMessagingSend).not.toHaveBeenCalled();
  });

  test('ao encerrar a ultima plataforma ativa, remove a entrada e marca o post como encerrado', async () => {
    postAtivoSnap = postComPlataformas({
      twitch: { link: 'https://twitch.tv/patrickson_plays', iniciadaEm: SERVER_TIMESTAMP },
    });

    await atualizarStatusPlataforma('twitch', false, null);

    expect(mockTxUpdate).toHaveBeenCalledWith(REF_POST_EXISTENTE, {
      'linksPorPlataforma.twitch': FIELD_DELETE,
      encerrada: true,
    });
  });

  test('ao encerrar uma plataforma quando outra ainda esta ativa, nao marca o post como encerrado', async () => {
    postAtivoSnap = postComPlataformas({
      twitch: { link: 'https://twitch.tv/patrickson_plays', iniciadaEm: SERVER_TIMESTAMP },
      kick: { link: 'https://kick.com/patrickson_plays', iniciadaEm: SERVER_TIMESTAMP },
    });

    await atualizarStatusPlataforma('twitch', false, null);

    expect(mockTxUpdate).toHaveBeenCalledWith(REF_POST_EXISTENTE, {
      'linksPorPlataforma.twitch': FIELD_DELETE,
    });
  });
});
