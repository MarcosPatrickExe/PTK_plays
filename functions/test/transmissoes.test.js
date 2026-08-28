const ordemChamadas = [];

const mockActivoGet = jest.fn();
const mockActivoDelete = jest.fn().mockImplementation(async () => {
  ordemChamadas.push('ativoDelete');
});
const mockActivoDocRef = { get: mockActivoGet, delete: mockActivoDelete };

const mockStudioSet = jest.fn().mockImplementation(async () => {
  ordemChamadas.push('studioSet');
});
const mockStudioDocRef = { set: mockStudioSet };

jest.mock('firebase-admin/firestore', () => ({
  getFirestore: () => ({
    collection: () => ({
      doc: () => ({
        collection: () => ({
          doc: () => mockActivoDocRef,
        }),
      }),
    }),
  }),
}));

jest.mock('@google-cloud/firestore', () => ({
  Firestore: jest.fn().mockImplementation(() => ({
    collection: () => ({
      doc: () => mockStudioDocRef,
    }),
  })),
}));

const {
  idDocumentoTransmissao,
  calcularDuracaoSegundos,
  registrarFimTransmissao,
} = require('../lib/transmissoes');

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

// registrarInicioTransmissao nao tem teste automatizado aqui (so grava, sem
// fluxo de leitura-delete-escrita pra proteger); registrarFimTransmissao e
// testada abaixo com firebase-admin/firestore e @google-cloud/firestore
// mockados, sem precisar de credenciais reais nem emulador.
describe('registrarFimTransmissao', () => {
  beforeEach(() => {
    ordemChamadas.length = 0;
    mockActivoGet.mockReset();
    mockActivoDelete.mockClear();
    mockStudioSet.mockClear();
  });

  test('so apaga o estado ativo depois de confirmar a escrita em transmissoes', async () => {
    mockActivoGet.mockResolvedValue({
      exists: true,
      data: () => ({
        idDaTransmissao: 'abc123',
        iniciadaEm: '2026-01-01T10:00:00.000Z',
      }),
    });

    await registrarFimTransmissao({ plataforma: 'twitch', resolverVod: async () => ({ vodId: 'v1' }) });

    expect(ordemChamadas).toEqual(['studioSet', 'ativoDelete']);
  });

  test('nao apaga o estado ativo se resolverVod falhar (permite retry do webhook)', async () => {
    mockActivoGet.mockResolvedValue({
      exists: true,
      data: () => ({
        idDaTransmissao: 'abc123',
        iniciadaEm: '2026-01-01T10:00:00.000Z',
      }),
    });

    await expect(
      registrarFimTransmissao({
        plataforma: 'twitch',
        resolverVod: async () => {
          throw new Error('Helix indisponivel');
        },
      }),
    ).rejects.toThrow('Helix indisponivel');

    expect(mockStudioSet).not.toHaveBeenCalled();
    expect(mockActivoDelete).not.toHaveBeenCalled();
  });

  test('nao apaga o estado ativo se a escrita em transmissoes falhar', async () => {
    mockActivoGet.mockResolvedValue({
      exists: true,
      data: () => ({
        idDaTransmissao: 'abc123',
        iniciadaEm: '2026-01-01T10:00:00.000Z',
      }),
    });
    mockStudioSet.mockRejectedValueOnce(new Error('escrita cross-project falhou'));

    await expect(registrarFimTransmissao({ plataforma: 'twitch' })).rejects.toThrow('escrita cross-project falhou');

    expect(mockActivoDelete).not.toHaveBeenCalled();
  });
});
