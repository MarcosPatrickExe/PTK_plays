import 'package:cloud_firestore/cloud_firestore.dart';

/// Uma mensagem da caixa de entrada do WhatsApp, como o webhook
/// (`functions/index.js`) gravou na coleção `mensagensWhatsapp`.
///
/// O app **nunca escreve** aqui — o `firestore.rules` trava a coleção
/// contra escrita de cliente, admin incluído. Tudo o que existe nela veio
/// de um evento que a Meta entregou no webhook.
class MensagemWhatsapp {
  /// O `wamid` da Meta, que também é o id do documento. É por ele que um
  /// status de entrega encontra a mensagem que já saiu.
  final String id;

  /// Só dígitos, no formato que a Meta usa (`5511999999999`).
  final String telefone;

  /// Nome do perfil do WhatsApp, quando a Meta manda. Só vem em mensagem
  /// recebida — status de entrega não traz contato.
  final String nomeDoContato;

  /// true quando a pessoa mandou pra gente; false quando saiu daqui.
  final bool recebida;

  /// `text`, `image`, `audio`... como a Meta classificou.
  final String tipo;

  /// O que a pessoa escreveu. Vazio em mídia sem legenda — quem resolve o
  /// que mostrar nesse caso é [resumo], não o webhook.
  final String texto;

  /// `sent`, `delivered`, `read` ou `failed`. Só existe em mensagem
  /// enviada, e só depois que a Meta confirma.
  final String status;

  /// Motivo da falha, quando [status] é `failed`.
  final String erro;

  /// Quando a mensagem foi criada. **Null em mensagem enviada** cujo
  /// documento nasceu de um status: a data do status não é a data do
  /// envio, e inventar uma seria pior que não ter.
  final DateTime? criadaEm;

  /// Última atividade: a chegada da mensagem, ou o status mais recente.
  /// É por aqui que a caixa de entrada ordena.
  final DateTime? atualizadaEm;

  const MensagemWhatsapp({
    required this.id,
    required this.telefone,
    this.nomeDoContato = '',
    required this.recebida,
    this.tipo = 'text',
    this.texto = '',
    this.status = '',
    this.erro = '',
    this.criadaEm,
    this.atualizadaEm,
  });

  factory MensagemWhatsapp.fromFirestore(String id, Map<String, dynamic> dados) {
    return MensagemWhatsapp(
      id: id,
      telefone: (dados['telefone'] ?? '') as String,
      nomeDoContato: (dados['nomeDoContato'] ?? '') as String,
      recebida: dados['direcao'] != 'enviada',
      tipo: (dados['tipo'] ?? 'text') as String,
      texto: (dados['texto'] ?? '') as String,
      status: (dados['status'] ?? '') as String,
      erro: (dados['erro'] ?? '') as String,
      criadaEm: _data(dados['criadaEm']),
      atualizadaEm: _data(dados['atualizadaEm']),
    );
  }

  static DateTime? _data(dynamic valor) {
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    return null;
  }

  DateTime get quando => atualizadaEm ?? criadaEm ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// O que aparece na lista. Mídia sem legenda vira um rótulo entre
  /// colchetes: o webhook grava texto vazio de propósito, pra não inventar
  /// palavras que a pessoa não escreveu.
  String get resumo {
    if (texto.isNotEmpty) return texto;
    switch (tipo) {
      case 'image':
        return '[imagem]';
      case 'video':
        return '[vídeo]';
      case 'audio':
        return '[áudio]';
      case 'document':
        return '[documento]';
      case 'sticker':
        return '[figurinha]';
      case 'location':
        return '[localização]';
      case 'contacts':
        return '[contato]';
      default:
        return '[$tipo]';
    }
  }

  /// Rótulo curto do status, pra linha da conversa. Vazio quando não há o
  /// que dizer (mensagem recebida, ou enviada sem confirmação ainda).
  String get rotuloDoStatus {
    if (recebida) return '';
    switch (status) {
      case 'sent':
        return 'Enviada';
      case 'delivered':
        return 'Entregue';
      case 'read':
        return 'Lida';
      case 'failed':
        return erro.isEmpty ? 'Falhou' : 'Falhou: $erro';
      default:
        return '';
    }
  }

  bool get falhou => status == 'failed';
}

/// Uma conversa: todas as mensagens trocadas com um mesmo número.
class ConversaWhatsapp {
  final String telefone;
  final String nomeDoContato;

  /// Da mais antiga pra mais recente, como se lê uma conversa.
  final List<MensagemWhatsapp> mensagens;

  const ConversaWhatsapp({
    required this.telefone,
    required this.nomeDoContato,
    required this.mensagens,
  });

  MensagemWhatsapp get ultima => mensagens.last;

  /// O nome do perfil, ou o telefone quando a Meta nunca mandou o nome
  /// (acontece em conversa que só teve mensagem enviada).
  String get titulo => nomeDoContato.isNotEmpty ? nomeDoContato : telefone;

  /// A última mensagem que a **pessoa** mandou. É ela que abre a janela de
  /// 24 horas — ver [janelaAbertaEm].
  MensagemWhatsapp? get ultimaRecebida {
    for (final mensagem in mensagens.reversed) {
      if (mensagem.recebida) return mensagem;
    }
    return null;
  }
}

/// Quanto tempo, depois da última mensagem da pessoa, a Cloud API deixa
/// responder com texto livre. Fora dessa janela só sai template aprovado
/// pela Meta — não é limite nosso, é regra da plataforma.
const Duration janelaDeAtendimentoWhatsapp = Duration(hours: 24);

/// Se dá pra responder essa conversa com texto livre agora.
///
/// Existe como função pura porque é a regra que decide o que a aba
/// WhatsApp do Painel ADM oferece: responder direto, ou avisar que só
/// template resolve. Conversa que nunca recebeu mensagem tem a janela
/// fechada desde sempre.
bool janelaAbertaEm(ConversaWhatsapp conversa, {DateTime? agora}) {
  final recebida = conversa.ultimaRecebida;
  if (recebida == null) return false;

  final momento = agora ?? DateTime.now();
  return momento.difference(recebida.quando) < janelaDeAtendimentoWhatsapp;
}

/// Agrupa mensagens soltas em conversas, uma por número, com a de
/// atividade mais recente primeiro.
///
/// Separado do Firestore de propósito: é aqui que mora a lógica que a
/// caixa de entrada precisa acertar (qual é a última mensagem, qual nome
/// mostrar), e testar isso não deveria exigir Firebase nenhum.
List<ConversaWhatsapp> agruparEmConversas(List<MensagemWhatsapp> mensagens) {
  final porTelefone = <String, List<MensagemWhatsapp>>{};
  for (final mensagem in mensagens) {
    if (mensagem.telefone.isEmpty) continue;
    porTelefone.putIfAbsent(mensagem.telefone, () => []).add(mensagem);
  }

  final conversas = porTelefone.entries.map((entrada) {
    final ordenadas = [...entrada.value]..sort((a, b) => a.quando.compareTo(b.quando));

    // O nome vem da mensagem recebida mais recente que trouxe um: a pessoa
    // pode ter trocado o nome do perfil desde a primeira conversa.
    var nome = '';
    for (final mensagem in ordenadas.reversed) {
      if (mensagem.nomeDoContato.isNotEmpty) {
        nome = mensagem.nomeDoContato;
        break;
      }
    }

    return ConversaWhatsapp(telefone: entrada.key, nomeDoContato: nome, mensagens: ordenadas);
  }).toList();

  conversas.sort((a, b) => b.ultima.quando.compareTo(a.ultima.quando));
  return conversas;
}
