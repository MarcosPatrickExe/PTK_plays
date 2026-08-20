const crypto = require('crypto');
const { verificarHandshakeWebhook, assinaturaValida } = require('../src/webhook');

describe('verificarHandshakeWebhook', () => {
  test('aceita handshake valido e retorna o challenge', () => {
    const resultado = verificarHandshakeWebhook({
      query: { 'hub.mode': 'subscribe', 'hub.verify_token': 'segredo123', 'hub.challenge': 'abc' },
      tokenEsperado: 'segredo123',
    });
    expect(resultado).toEqual({ ok: true, challenge: 'abc' });
  });

  test('rejeita quando o token nao bate', () => {
    const resultado = verificarHandshakeWebhook({
      query: { 'hub.mode': 'subscribe', 'hub.verify_token': 'errado', 'hub.challenge': 'abc' },
      tokenEsperado: 'segredo123',
    });
    expect(resultado.ok).toBe(false);
  });

  test('rejeita quando o modo nao e subscribe', () => {
    const resultado = verificarHandshakeWebhook({
      query: { 'hub.mode': 'unsubscribe', 'hub.verify_token': 'segredo123', 'hub.challenge': 'abc' },
      tokenEsperado: 'segredo123',
    });
    expect(resultado.ok).toBe(false);
  });

  test('rejeita quando falta o challenge', () => {
    const resultado = verificarHandshakeWebhook({
      query: { 'hub.mode': 'subscribe', 'hub.verify_token': 'segredo123' },
      tokenEsperado: 'segredo123',
    });
    expect(resultado.ok).toBe(false);
  });
});

describe('assinaturaValida', () => {
  const appSecret = 'app-secret-de-teste';
  const corpoBruto = Buffer.from(JSON.stringify({ object: 'whatsapp_business_account' }));

  function assinar(corpo, secret) {
    return 'sha256=' + crypto.createHmac('sha256', secret).update(corpo).digest('hex');
  }

  test('aceita assinatura calculada corretamente', () => {
    const headerAssinatura = assinar(corpoBruto, appSecret);
    expect(assinaturaValida({ corpoBruto, headerAssinatura, appSecret })).toBe(true);
  });

  test('rejeita assinatura calculada com outro app secret', () => {
    const headerAssinatura = assinar(corpoBruto, 'outro-secret');
    expect(assinaturaValida({ corpoBruto, headerAssinatura, appSecret })).toBe(false);
  });

  test('rejeita corpo adulterado (assinatura nao bate mais)', () => {
    const headerAssinatura = assinar(corpoBruto, appSecret);
    const corpoAdulterado = Buffer.from(JSON.stringify({ object: 'outra_coisa' }));
    expect(assinaturaValida({ corpoBruto: corpoAdulterado, headerAssinatura, appSecret })).toBe(false);
  });

  test('rejeita header ausente ou mal formatado', () => {
    expect(assinaturaValida({ corpoBruto, headerAssinatura: undefined, appSecret })).toBe(false);
    expect(assinaturaValida({ corpoBruto, headerAssinatura: 'token-sem-prefixo', appSecret })).toBe(false);
  });
});
