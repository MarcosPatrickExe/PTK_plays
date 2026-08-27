# Prompt — escrever `transmissoes` no Firestore do PTK AI Studio

Contexto: este arquivo é o pedido pronto para colar na sessão que trabalha
neste repositório (`PTK_plays`). O IAM já foi concedido no console do GCP —
a conta de serviço das Functions (`696548413882-compute@developer.gserviceaccount.com`)
recebeu o papel `roles/datastore.user` no projeto `ptk-ai-studio`. Falta só
o código.

---

Adicione às Functions de detecção de live uma escrita para o Firestore de
**outro projeto Firebase**, `ptk-ai-studio`, na coleção `transmissoes`. A
conta de serviço das Functions já recebeu `roles/datastore.user` nesse
projeto, então **use Application Default Credentials — não crie nem baixe
chave de service account**:

```js
const { Firestore } = require('@google-cloud/firestore');
const studio = new Firestore({ projectId: 'ptk-ai-studio' });
```

**Não altere nada do que as Functions já escrevem hoje** no Firestore do
`ptk-plays` — isso é uma escrita adicional, o app da comunidade não pode
mudar de comportamento.

Um documento por transmissão e por plataforma. Use um **ID
determinístico**, `${plataforma}_${idDaTransmissao}`, e escreva sempre com
`{ merge: true }` — a verificação agendada do YouTube roda várias vezes
durante a mesma live e não pode gerar documento duplicado.

Campos:

| Campo | Quando | Conteúdo |
|---|---|---|
| `plataforma` | início | `'twitch'`, `'kick'` ou `'youtube'` |
| `iniciadaEm` | início | timestamp da detecção |
| `urlDaLive` | início | URL de assistir |
| `idDaTransmissao` | início | id da transmissão na plataforma |
| `encerrada` | ambos | `false` no início, `true` no fim |
| `encerradaEm` | fim | timestamp da detecção do fim |
| `duracaoSegundos` | fim | duração da transmissão |
| `vodId` | fim | id da gravação, se a plataforma expuser |
| `vodUrl` | fim | URL direta da gravação |

**`vodId` e `vodUrl` são os campos mais importantes** — eliminam o upload
manual do vídeo. No YouTube deve sair de graça: a verificação agendada já
recebe o `videoId`, e depois que a live termina esse id **é** o VOD. Na
Twitch, o `stream.online` do EventSub não traz o VOD; é preciso uma
chamada à Helix `/videos` depois do fim. Se em alguma plataforma não der
pra obter, **deixe o campo ausente** — não invente e não chute.
