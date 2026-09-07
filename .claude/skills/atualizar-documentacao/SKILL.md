---
name: atualizar-documentacao
description: Atualiza a documentação viva do PTK Plays — CHECKPOINT.md, ROADMAP.md e CLAUDE.md — depois de entregar uma tarefa, ou quando o usuário pedir pra "atualizar o checkpoint", "registrar o que fizemos" ou preparar a sessão pra um /clear. Use também antes de encerrar uma sessão longa.
---

# Atualizando a documentação do PTK Plays

Este repositório tem três documentos vivos, e cada um responde a uma
pergunta diferente. Escrever a coisa certa no arquivo errado é o jeito
mais fácil de tornar os três inúteis.

| Arquivo | Pergunta que responde | Quando muda |
|---|---|---|
| `CHECKPOINT.md` | "Em que pé está o projeto **hoje**?" | Toda entrega |
| `ROADMAP.md` | "**Por que** isso foi feito assim?" | Toda decisão técnica |
| `CLAUDE.md` | "O que vale pra **sempre**?" | Raramente |

Os outros dois documentos (`README.md` e `REGRAS_DA_COMUNIDADE.md`) não
fazem parte deste fluxo — só mexa neles se a tarefa foi sobre eles.

## Antes de escrever qualquer coisa

Levante os fatos em vez de confiar na memória da conversa:

```bash
export PATH="$PATH:/opt/flutter/bin"
git log --oneline $(git describe --tags --abbrev=0 2>/dev/null || echo origin/main)..HEAD
flutter test 2>&1 | tail -3            # o número de testes vai pro CHECKPOINT
cd functions && npm test 2>&1 | tail -5  # idem, os do backend
```

Confira também o que **não** está no código: se o usuário disse que rodou
um deploy, que mesclou um PR ou que uma pendência saiu, isso muda o
CHECKPOINT e não aparece em `git log`.

## CHECKPOINT.md — o estado de hoje

É o documento que uma sessão nova lê depois de um `/clear`. Escreva pra
alguém que **não viu esta conversa**.

Atualize sempre:

1. **A data no topo.**
2. **"⚠️ O que precisa de atenção AGORA"** — a seção mais importante do
   arquivo. Só entra aqui o que **bloqueia trabalho** ou o que faria a
   próxima sessão quebrar algo por não saber. Ordene por urgência e
   **renumere as referências cruzadas** ("ver atenção 2") quando a ordem
   mudar. Item resolvido **sai da lista** — não vira "✅ feito".

   **Um item de atenção precisa ser acionável sem contexto nenhum.**
   "Confirmar que o webhook está gravando" não serve: quem lê depois de um
   `/clear` não sabe onde clicar nem o que significa falhar. Um item bom
   responde quatro coisas, e vale usar subtítulos em itálico pra separar:

   - ***O que é*** — em duas linhas, pra quem nunca viu.
   - ***Por que ainda é atenção*** — o que exatamente não foi verificado.
     Cuidado com o mais traiçoeiro: "o deploy foi feito" costuma esconder
     uma metade que não depende de código (configuração num painel
     externo, uma chave, uma inscrição) e que nada no repositório
     denuncia.
   - ***Como confirmar*** — passos numerados, com o comando exato e o
     lugar exato (nome da tela, do menu, do campo). Se um valor não puder
     ser afirmado com certeza, diga como descobri-lo em vez de chutar
     (`firebase functions:list` em vez de uma URL inventada).
   - ***O que cada resultado significa*** — os ramos de falha, cada um
     apontando pro culpado provável. Quando houver um comando que
     distingue os ramos, ele é a parte mais valiosa do item inteiro.

   Ao citar log, erro ou mensagem, **copie a string do código** e confira
   que ela ainda existe — um trecho de log que não bate com a fonte manda
   a próxima sessão procurar o que não há.

3. **"Estado do git"** — último merge em `main`, quantos commits a branch
   tem além disso, e se há PR aberto.
4. **"Saúde do projeto"** — contagem de testes do Flutter e do backend.
5. **"Deploys"** — o que já foi publicado e o que está pendente. Deploy é
   feito pelo usuário, então esta seção é a única fonte de verdade sobre
   o que está no ar.
6. **"Pendências, em ordem de esforço"** — renumere quando algo sair.

Duas regras de conteúdo que fazem esse arquivo valer alguma coisa:

- **Registre a armadilha, não o resultado.** "Recortei o fundo das artes"
  não ajuda ninguém; "semear as laterais come o braço da selfie, porque o
  antebraço encosta na borda" evita que a próxima sessão repita o erro.
- **Marque o que é suposição.** Use "**Não confirmado**:" ou "**Não
  verificado**:" quando algo não foi checado nesta sessão — status de
  loja, se um deploy foi mesmo feito, se um serviço externo está
  configurado. Uma suposição escrita como fato vira decisão errada duas
  sessões depois.

## ROADMAP.md — por que foi feito assim

Registro cronológico, mais antigo em cima. Cada entrega ganha uma seção
`# Título (DD/mmm/AAAA)` no **fim** do arquivo, com subseções `##` por
assunto.

O que vale escrever aqui é o **raciocínio**, não o changelog: o que estava
errado, por que a solução óbvia não servia, e o que decidiu o desenho.
Quando o CHECKPOINT ficar raso sobre algo, é aqui que a explicação inteira
tem que estar.

Se a tarefa foi puramente mecânica (bump de versão, troca de asset sem
decisão de layout), não force uma entrada.

## CLAUDE.md — o que vale pra sempre

Mexa **pouco**. Só entra aqui o que vale pra toda tarefa futura,
independente do que estiver sendo feito:

- regras de processo que o usuário declarou (testes obrigatórios, um
  commit por arquivo, convenção de commits);
- padrões de UI que toda tela nova precisa seguir;
- restrições externas com prazo ou consequência (Google Play, signing,
  gatilho de build do Codemagic).

Não entra: estado atual, pendências, decisão de uma tarefa específica.
Isso é CHECKPOINT ou ROADMAP. Na dúvida, **não** escreva no CLAUDE.md — um
arquivo de regras que vira diário deixa de ser lido.

## Ao fechar

- **Um commit por arquivo alterado** — regra permanente deste repositório.
  A mensagem explica *o que mudou no entendimento do projeto*, não "atualiza
  o checkpoint".
- Não crie tag `v*`: ela dispara build no Codemagic e só sai quando o
  usuário pedir explicitamente.
- Se a documentação foi atualizada pra preparar um `/clear`, diga ao
  usuário o que ficou registrado — é a última chance dele corrigir algo
  antes do contexto sumir.
