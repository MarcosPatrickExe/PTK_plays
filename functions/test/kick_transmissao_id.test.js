const { extrairIdDaTransmissaoKick } = require('../lib/kick');

// Confirmado em docs.kick.com/events/event-types: o payload do
// `livestream.status.updated` traz broadcaster/is_live/title/started_at/
// ended_at, sem nenhum id de transmissao dedicado - por isso derivamos o
// id do started_at em vez de inventar um campo que nao existe.
describe('extrairIdDaTransmissaoKick', () => {
  test('deriva um id estavel a partir do started_at', () => {
    const id = extrairIdDaTransmissaoKick({ started_at: '2026-01-01T10:00:00Z' });
    expect(id).toBe('20260101100000');
  });

  test('retorna null (nao inventa) quando o payload nao tem started_at', () => {
    expect(extrairIdDaTransmissaoKick({ is_live: true, title: 'Live sem started_at' })).toBeNull();
    expect(extrairIdDaTransmissaoKick({})).toBeNull();
    expect(extrairIdDaTransmissaoKick(null)).toBeNull();
  });
});
