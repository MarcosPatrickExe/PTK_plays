const { buscarDadosAoVivoTwitch } = require('../lib/twitch');

describe('buscarDadosAoVivoTwitch', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  test('retorna titulo, jogo e thumbnailUrl com os placeholders de tamanho substituidos', async () => {
    global.fetch = jest
      .fn()
      .mockResolvedValueOnce({ ok: true, json: async () => ({ access_token: 'app-token' }) })
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          data: [
            {
              title: 'Rankeada até de madrugada',
              game_name: 'Valorant',
              thumbnail_url: 'https://static-cdn.jtvnw.net/previews-ttv/live_user_x-{width}x{height}.jpg',
            },
          ],
        }),
      });

    const dados = await buscarDadosAoVivoTwitch('123', 'client-id', 'client-secret');

    expect(dados).toEqual({
      titulo: 'Rankeada até de madrugada',
      jogo: 'Valorant',
      thumbnailUrl: 'https://static-cdn.jtvnw.net/previews-ttv/live_user_x-440x248.jpg',
    });
  });

  test('retorna null quando a Twitch nao lista nenhuma stream ao vivo pra esse broadcaster', async () => {
    global.fetch = jest
      .fn()
      .mockResolvedValueOnce({ ok: true, json: async () => ({ access_token: 'app-token' }) })
      .mockResolvedValueOnce({ ok: true, json: async () => ({ data: [] }) });

    expect(await buscarDadosAoVivoTwitch('123', 'client-id', 'client-secret')).toBeNull();
  });

  test('retorna null quando falha ao obter o token de app', async () => {
    global.fetch = jest.fn().mockResolvedValueOnce({ ok: false, status: 401, text: async () => 'erro' });

    expect(await buscarDadosAoVivoTwitch('123', 'client-id', 'client-secret')).toBeNull();
  });
});
