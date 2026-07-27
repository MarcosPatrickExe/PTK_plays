# PTK Plays — Instruções para o Claude

## Regra permanente: testes unitários

Sempre que eu implementar ou corrigir algo no código (feature nova, bugfix,
refatoração), devo:

1. Implementar a mudança.
2. Escrever (ou atualizar) um teste unitário/widget que comprove o
   comportamento implementado/corrigido.
3. Rodar `flutter test` e `flutter analyze` antes de reportar a tarefa como
   concluída.
4. Contar ao usuário o que foi feito no código **e** qual teste cobre isso.
5. Se o teste não conseguir ser validado de ponta a ponta (ex: depende de
   infraestrutura externa — Firebase, Google/Apple Sign-In nativo, chaves de
   API, dispositivo físico — que não está disponível neste ambiente), avisar
   claramente qual é o motivo e o que falta para o usuário validar por conta
   própria.

## Convenção de commits

Meus commits usam o identificador de git configurado no ambiente
(`Claude <noreply@anthropic.com>`), já que não altero a configuração global
do git. Para refletir a autoria real do trabalho, incluo a trailer:

```
Co-Authored-By: Marcos Patrick <marcospatrick039474@gmail.com>
```

em toda mensagem de commit feita neste repositório.
