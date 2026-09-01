# Regras da comunidade — PTK Plays

Estas são as regras de convivência do Feed do PTK Plays. Valem pra todo
mundo: inscrito, VIP e admin.

## 1. Respeito acima de tudo

**Não é permitido xingar, ofender ou humilhar outras pessoas.** Isso inclui
xingamento direto, apelido pejorativo, ironia feita pra diminuir alguém,
ataque à aparência, à religião, à origem, à orientação sexual, à identidade
de gênero ou a qualquer característica pessoal.

Discordar é normal e faz parte. Discordar xingando, não.

Também não é permitido:

- ameaçar, intimidar ou perseguir alguém;
- incitar violência ou ódio contra pessoas ou grupos;
- expor dados pessoais de outra pessoa (endereço, telefone, documento,
  print de conversa privada) sem o consentimento dela.

## 2. Nada de conteúdo sexual ou sensível

O PTK Plays é um app de comunidade de games, aberto a público variado.
**Conteúdo sexual, nudez, gore, automutilação, uso de drogas e violência
gráfica não são permitidos** — nem em imagem, nem em vídeo, nem em texto,
nem em link pra fora.

## 3. Nada de spam nem golpe

- Sem corrente, divulgação repetida ou publicação em massa.
- Sem link de phishing, "ganhe skins grátis", pirâmide ou venda de conta.
- Sem se passar por outra pessoa, pelo canal ou pela administração.

## 4. Quem pode publicar o quê

| Cargo    | Texto | Foto e vídeo | Enquete |
| -------- | :---: | :----------: | :-----: |
| Inscrito |  sim  |     não      |   não   |
| VIP      |  sim  |     não      |   não   |
| Admin    |  sim  |     sim      |   sim   |

**Por que só o admin publica imagem e vídeo**: mídia é o que dá pra publicar
de pior sem ninguém revisar antes — uma imagem imprópria já causou o estrago
no instante em que aparece no feed de alguém, e o app não tem (ainda) fila de
moderação nem detecção automática de conteúdo. Texto, por outro lado, dá pra
ler, denunciar e apagar. Enquanto não existir moderação prévia de mídia,
imagem e vídeo ficam com quem responde pela comunidade.

Post de admin também aparece acima dos demais no feed — não é privilégio
estético: é pra aviso do canal (live, sorteio, mudança de horário) não se
perder no meio das outras publicações.

## 5. O que acontece com quem descumpre

O admin pode, pelo Painel ADM:

1. **apagar a publicação** (qualquer post, de qualquer pessoa);
2. **suspender a conta** por um período;
3. **banir a conta** em caso grave ou reincidência.

O autor de um post sempre pode apagar o próprio post, sem precisar pedir.

## 6. Onde essas regras viram código

Regra escrita que não é aplicada em lugar nenhum não vale muito. Onde cada
uma mora no repositório:

- **`firestore.rules`** (regra de `create` em `/posts`) — é o que de fato
  impede um inscrito de publicar mídia. A regra recusa o tipo `avisoMidia`
  pra quem não é admin, e recusa também um `avisoTexto` que venha com
  `fotoUrl` ou `videoUrl` pendurado. Passar por fora do app não ajuda: quem
  decide é o servidor.
- **`lib/components/NovoPost.dart`** — a UI só oferece os botões de anexar
  foto e vídeo pro admin. É conveniência, não segurança: quem barra de
  verdade é a regra acima.
- **`lib/view/PainelAdmin.dart`** — apagar post, suspender e banir conta.
- **`storage.rules`** — limita tamanho e tipo do arquivo enviado
  (imagem até 10 MB, vídeo até 50 MB).

## 7. Ainda não existe (e devia)

Registrado aqui pra não se perder:

- **Denúncia dentro do app**: hoje o caminho é falar com o admin por fora.
- **Moderação prévia ou automática de mídia**: é o que teria de existir pra
  liberar imagem pros inscritos com segurança.
- **Filtro de palavrão no texto**: a regra 1 depende de alguém ler e agir.

---

_Última revisão: 01/set/2026._
