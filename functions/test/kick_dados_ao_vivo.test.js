const { buscarDadosAoVivoKick } = require('../lib/kick');

describe('buscarDadosAoVivoKick', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  test('retorna jogo (category.name) e thumbnailUrl quando thumbnail vem como {url}', async () => {
    global.fetch = jest
      .fn()
      .mockResolvedValueOnce({ ok: true, json: async () => ({ access_token: 'app-token' }) })
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          data: [{ category: { id: 1, name: 'Just Chatting' }, thumbnail: { url: 'https://kick.com/preview.jpg' } }],
        }),
      });

    const dados = await buscarDadosAoVivoKick('456', 'client-id', 'client-secret');

    expect(dados).toEqual({ jogo: 'Just Chatting', thumbnailUrl: 'https://kick.com/preview.jpg' });
  });

  test('tambem aceita thumbnail como string direta', async () => {
    global.fetch = jest
      .fn()
      .mockResolvedValueOnce({ ok: true, json: async () => ({ access_token: 'app-token' }) })
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({ data: [{ category: { name: 'Valorant' }, thumbnail: 'https://kick.com/preview.jpg' }] }),
      });

    const dados = await buscarDadosAoVivoKick('456', 'client-id', 'client-secret');

    expect(dados).toEqual({ jogo: 'Valorant', thumbnailUrl: 'https://kick.com/preview.jpg' });
  });

  test('retorna null quando a Kick nao lista nenhuma livestream ativa pra esse usuario', async () => {
    global.fetch = jest
      .fn()
      .mockResolvedValueOnce({ ok: true, json: async () => ({ access_token: 'app-token' }) })
      .mockResolvedValueOnce({ ok: true, json: async () => ({ data: [] }) });

    expect(await buscarDadosAoVivoKick('456', 'client-id', 'client-secret')).toBeNull();
  });

  test('retorna null quando falha ao obter o token de app', async () => {
    global.fetch = jest.fn().mockResolvedValueOnce({ ok: false, status: 401, text: async () => 'erro' });

    expect(await buscarDadosAoVivoKick('456', 'client-id', 'client-secret')).toBeNull();
  });
});
