const { extrairIdDaTransmissaoKick } = require('../lib/kick');

// A Kick nao documenta um id de transmissao dedicado no webhook
// `livestream.status.updated`. Esses testes fixam o comportamento
// defensivo implementado em kick.js (ver comentario la): tenta alguns
// campos plausiveis do payload e, se nenhum vier, nao inventa nada.
describe('extrairIdDaTransmissaoKick', () => {
  test('usa livestream.id quando presente', () => {
    expect(extrairIdDaTransmissaoKick({ livestream: { id: 42 } })).toBe('42');
  });

  test('usa body.id quando livestream.id nao vem', () => {
    expect(extrairIdDaTransmissaoKick({ id: 'abc' })).toBe('abc');
  });

  test('deriva do started_at quando nao ha id nenhum', () => {
    const id = extrairIdDaTransmissaoKick({ started_at: '2026-01-01T10:00:00Z' });
    expect(id).toBe('20260101100000');
  });

  test('retorna null (nao inventa) quando o payload nao tem nada usavel', () => {
    expect(extrairIdDaTransmissaoKick({ is_live: true })).toBeNull();
    expect(extrairIdDaTransmissaoKick({})).toBeNull();
    expect(extrairIdDaTransmissaoKick(null)).toBeNull();
  });
});
