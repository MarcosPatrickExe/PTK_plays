const { parseDuracaoTwitch } = require('../lib/twitchDuracao');

describe('parseDuracaoTwitch', () => {
  test('parseia horas, minutos e segundos', () => {
    expect(parseDuracaoTwitch('6h26m14s')).toBe(6 * 3600 + 26 * 60 + 14);
  });

  test('parseia so minutos e segundos', () => {
    expect(parseDuracaoTwitch('45m10s')).toBe(45 * 60 + 10);
  });

  test('parseia so segundos', () => {
    expect(parseDuracaoTwitch('30s')).toBe(30);
  });

  test('retorna null pra string vazia ou ausente', () => {
    expect(parseDuracaoTwitch('')).toBeNull();
    expect(parseDuracaoTwitch(null)).toBeNull();
    expect(parseDuracaoTwitch(undefined)).toBeNull();
  });

  test('retorna null pra formato que nao bate com nenhuma unidade', () => {
    expect(parseDuracaoTwitch('abc')).toBeNull();
  });
});
