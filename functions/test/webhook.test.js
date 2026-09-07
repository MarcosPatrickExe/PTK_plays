const crypto = require('crypto');
const {
  verificarHandshakeWebhook,
  assinaturaValida,
  extrairEventosDoWebhook,
  idDocumentoMensagem,
} = require('../src/webhook');

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

describe('extrairEventosDoWebhook', () => {
  function envelope(valor) {
    return { object: 'whatsapp_business_account', entry: [{ id: 'waba-1', changes: [{ field: 'messages', value: valor }] }] };
  }

  test('mensagem de texto recebida vira um documento com nome do contato', () => {
    const eventos = extrairEventosDoWebhook(envelope({
      contacts: [{ wa_id: '5511999999999', profile: { name: 'Marcos' } }],
      messages: [{
        from: '5511999999999',
        id: 'wamid.ABC',
        timestamp: '1757000000',
        type: 'text',
        text: { body: 'esqueci minha senha' },
      }],
    }));

    expect(eventos).toHaveLength(1);
    expect(eventos[0].docId).toBe('wamid.ABC');
    expect(eventos[0].dados).toMatchObject({
      idNaMeta: 'wamid.ABC',
      telefone: '5511999999999',
      nomeDoContato: 'Marcos',
      direcao: 'recebida',
      tipo: 'text',
      texto: 'esqueci minha senha',
    });
    expect(eventos[0].dados.criadaEm).toEqual(new Date(1757000000 * 1000));
  });

  test('status de entrega vira o MESMO documento da mensagem enviada', () => {
    const eventos = extrairEventosDoWebhook(envelope({
      statuses: [{ id: 'wamid.XYZ', status: 'delivered', timestamp: '1757000100', recipient_id: '5511888888888' }],
    }));

    expect(eventos).toHaveLength(1);
    expect(eventos[0].docId).toBe('wamid.XYZ');
    expect(eventos[0].dados).toMatchObject({
      direcao: 'enviada',
      status: 'delivered',
      telefone: '5511888888888',
    });
    // Sem criadaEm: a data do status nao e a data do envio.
    expect(eventos[0].dados.criadaEm).toBeUndefined();
  });

  test('falha de envio guarda o motivo, pra o painel dizer o que houve', () => {
    const eventos = extrairEventosDoWebhook(envelope({
      statuses: [{
        id: 'wamid.ERR',
        status: 'failed',
        timestamp: '1757000200',
        recipient_id: '5511777777777',
        errors: [{ code: 131047, title: 'Re-engagement message' }],
      }],
    }));

    expect(eventos[0].dados.status).toBe('failed');
    expect(eventos[0].dados.erro).toBe('131047 - Re-engagement message');
  });

  test('midia com legenda usa a legenda; sem legenda, texto fica vazio', () => {
    const comLegenda = extrairEventosDoWebhook(envelope({
      messages: [{ from: '551199', id: 'wamid.1', timestamp: '1757000000', type: 'image', image: { caption: 'olha isso' } }],
    }));
    expect(comLegenda[0].dados.texto).toBe('olha isso');

    const semLegenda = extrairEventosDoWebhook(envelope({
      messages: [{ from: '551199', id: 'wamid.2', timestamp: '1757000000', type: 'image', image: {} }],
    }));
    // Vazio de proposito: quem mostra "[imagem]" e a UI, a partir do tipo.
    expect(semLegenda[0].dados.texto).toBe('');
    expect(semLegenda[0].dados.tipo).toBe('image');
  });

  test('mensagens e status no mesmo envelope saem juntos', () => {
    const eventos = extrairEventosDoWebhook(envelope({
      messages: [{ from: '551199', id: 'wamid.M', timestamp: '1757000000', type: 'text', text: { body: 'oi' } }],
      statuses: [{ id: 'wamid.S', status: 'read', timestamp: '1757000050', recipient_id: '551199' }],
    }));
    expect(eventos.map((e) => e.docId)).toEqual(['wamid.M', 'wamid.S']);
  });

  test('payload vazio, malformado ou sem id nao gera evento nenhum', () => {
    expect(extrairEventosDoWebhook(undefined)).toEqual([]);
    expect(extrairEventosDoWebhook({})).toEqual([]);
    expect(extrairEventosDoWebhook(envelope({}))).toEqual([]);
    expect(extrairEventosDoWebhook(envelope({ messages: [{ from: '551199', type: 'text' }] }))).toEqual([]);
  });

  test('timestamp ausente ou invalido nao vira Invalid Date', () => {
    const eventos = extrairEventosDoWebhook(envelope({
      messages: [{ from: '551199', id: 'wamid.T', type: 'text', text: { body: 'oi' } }],
    }));
    expect(eventos[0].dados.criadaEm.getTime()).not.toBeNaN();
  });
});

describe('idDocumentoMensagem', () => {
  test('troca a barra do base64, que o Firestore nao aceita em id', () => {
    expect(idDocumentoMensagem('wamid.HBgN/abc/def=')).toBe('wamid.HBgN_abc_def=');
  });

  test('e deterministico: a mesma mensagem sempre cai no mesmo documento', () => {
    expect(idDocumentoMensagem('wamid.ABC')).toBe(idDocumentoMensagem('wamid.ABC'));
  });
});
