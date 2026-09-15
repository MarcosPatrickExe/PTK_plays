'use strict';

const {
  normalizarEmail,
  emailPareceValido,
  chaveDeFrequencia,
  dentroDoLimite,
  JANELA_EM_MS,
  LIMITE_POR_JANELA,
} = require('../src/preTesteDeEmail');

describe('normalizarEmail', () => {
  test('tira espaco e baixa a caixa', () => {
    expect(normalizarEmail('  Fulano@Gmail.COM ')).toBe('fulano@gmail.com');
  });

  test('o que nao e texto vira vazio', () => {
    // O `data` de um callable vem do cliente e pode ser qualquer coisa:
    // null, numero, objeto. Sem isto, um `.trim()` em cima disso derrubaria
    // a funcao com 500 em vez de responder.
    expect(normalizarEmail(null)).toBe('');
    expect(normalizarEmail(undefined)).toBe('');
    expect(normalizarEmail(42)).toBe('');
    expect(normalizarEmail({ email: 'x@y.z' })).toBe('');
  });
});

describe('emailPareceValido', () => {
  test('aceita o formato basico', () => {
    expect(emailPareceValido('fulano@teste.com')).toBe(true);
    expect(emailPareceValido('a.b+c@sub.dominio.com.br')).toBe(true);
  });

  test('recusa o que nao tem chance de ser endereco', () => {
    // Nao e validacao de verdade — e pra nao gastar uma consulta ao Auth,
    // e uma vaga no limite de quem chamou, com texto solto.
    expect(emailPareceValido('')).toBe(false);
    expect(emailPareceValido('fulano')).toBe(false);
    expect(emailPareceValido('fulano@')).toBe(false);
    expect(emailPareceValido('fulano@teste')).toBe(false);
    expect(emailPareceValido('com espaco@teste.com')).toBe(false);
  });
});

describe('chaveDeFrequencia', () => {
  test('o mesmo IP na mesma janela cai na mesma chave', () => {
    const a = chaveDeFrequencia('203.0.113.7', 1_000_000, JANELA_EM_MS);
    const b = chaveDeFrequencia('203.0.113.7', 1_000_000 + 5_000, JANELA_EM_MS);

    expect(a).toBe(b);
  });

  test('a janela seguinte comeca num documento novo', () => {
    // A janela entra na CHAVE, e nao num campo do documento. E o que
    // dispensa uma transacao pra zerar o contador quando o relogio vira:
    // o intervalo novo simplesmente escreve em outro lugar.
    const a = chaveDeFrequencia('203.0.113.7', 0, JANELA_EM_MS);
    const b = chaveDeFrequencia('203.0.113.7', JANELA_EM_MS, JANELA_EM_MS);

    expect(a).not.toBe(b);
  });

  test('IPs diferentes nao se misturam', () => {
    const a = chaveDeFrequencia('203.0.113.7', 0, JANELA_EM_MS);
    const b = chaveDeFrequencia('198.51.100.2', 0, JANELA_EM_MS);

    expect(a).not.toBe(b);
  });

  test('o IP nao aparece na chave', () => {
    // O IP e dado pessoal. Guardar uma lista deles pra contar requisicao
    // seria criar um registro de quem tentou se cadastrar e quando — dado
    // que ninguem pediu e que teria que ser protegido. O hash conta igual e
    // nao identifica ninguem depois.
    const ip = '203.0.113.7';
    const chave = chaveDeFrequencia(ip, 0, JANELA_EM_MS);

    expect(chave).not.toContain(ip);
    expect(chave).not.toContain('203');
  });

  test('sem IP ainda gera chave, em vez de quebrar', () => {
    // Chamada de emulador e alguns proxies chegam sem IP. Melhor todas
    // caírem no mesmo balde do que a funcao estourar.
    expect(chaveDeFrequencia(undefined, 0, JANELA_EM_MS)).toBeTruthy();
    expect(chaveDeFrequencia(null, 0, JANELA_EM_MS)).toBeTruthy();
  });
});

describe('dentroDoLimite', () => {
  test('a primeira pergunta passa', () => {
    expect(dentroDoLimite(0)).toBe(true);
    expect(dentroDoLimite(undefined)).toBe(true);
  });

  test('passa ate o limite, e barra a partir dele', () => {
    expect(dentroDoLimite(LIMITE_POR_JANELA - 1)).toBe(true);
    expect(dentroDoLimite(LIMITE_POR_JANELA)).toBe(false);
    expect(dentroDoLimite(LIMITE_POR_JANELA + 500)).toBe(false);
  });

  test('o limite e folgado pra gente de verdade', () => {
    // Um cadastro faz UMA consulta. Mesmo quem erra o endereco varias
    // vezes nao chega perto. O numero existe pra quebrar o script que
    // testaria milhoes de enderecos, nao pra apertar quem se cadastra.
    expect(LIMITE_POR_JANELA).toBeGreaterThanOrEqual(20);
  });
});
