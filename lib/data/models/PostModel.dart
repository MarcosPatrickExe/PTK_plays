import 'package:cloud_firestore/cloud_firestore.dart';

/// Dados de uma plataforma dentro de um post do tipo aoVivo (ver
/// [PostModel.plataformasAoVivo]). [jogo] e [thumbnailUrl] so vem
/// preenchidos pra Twitch e Kick hoje - o YouTube nao busca esses dados
/// (ver `functions/lib/youtube.js`).
class PostPlataformaAoVivo {
  final String link;
  final String? titulo;
  final String? jogo;
  final String? thumbnailUrl;
  final DateTime? iniciadaEm;

  /// false depois que a transmissao dessa plataforma encerrou. Entradas
  /// legadas (sem o campo) contam como ao vivo - era o unico estado
  /// possivel antes, ja que a plataforma era apagada do post ao encerrar.
  final bool aoVivo;
  final DateTime? encerradaEm;
  final int? duracaoSegundos;

  /// Link da gravacao, preenchido no fim da transmissao. A Kick nao expoe
  /// VOD, entao la fica sempre nulo.
  final String? vodUrl;

  const PostPlataformaAoVivo({
    required this.link,
    this.titulo,
    this.jogo,
    this.thumbnailUrl,
    this.iniciadaEm,
    this.aoVivo = true,
    this.encerradaEm,
    this.duracaoSegundos,
    this.vodUrl,
  });

  /// Pra onde o toque na badge leva: a gravacao quando a live ja acabou,
  /// senao a propria live.
  String get linkParaAbrir => (!aoVivo && vodUrl != null && vodUrl!.isNotEmpty) ? vodUrl! : link;

  /// Preview do card. Twitch e Kick mandam `thumbnailUrl` pronto; o YouTube
  /// nao manda nenhum, mas a miniatura dele e deduzivel do proprio id do
  /// video que ja esta no link (`watch?v=<id>`), num endereco publico e
  /// estavel. Retorna null quando nao da pra deduzir nada.
  String? get previewUrl {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) return thumbnailUrl;

    final videoId = Uri.tryParse(link)?.queryParameters['v'];
    if (videoId == null || videoId.isEmpty) return null;
    return 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
  }

  /// Le uma entrada de `linksPorPlataforma`. Aceita os dois formatos que
  /// existem no Firestore hoje:
  /// - **atual**: um mapa com `link` + os extras (titulo/jogo/thumbnailUrl/
  ///   iniciadaEm), gravado por `functions/lib/postAoVivo.js`;
  /// - **legado**: o link como texto puro, formato usado pelos posts
  ///   criados antes dos extras existirem. Sem esse ramo, os posts antigos
  ///   quebrariam a leitura do Feed inteiro (um `String` sendo lido como
  ///   `Map` lanca excecao dentro do stream).
  factory PostPlataformaAoVivo.fromDynamic(dynamic data) {
    if (data is String) return PostPlataformaAoVivo(link: data);
    if (data is Map) {
      final mapa = Map<String, dynamic>.from(data);
      return PostPlataformaAoVivo(
        link: mapa['link'] ?? '',
        titulo: mapa['titulo'],
        jogo: mapa['jogo'],
        thumbnailUrl: mapa['thumbnailUrl'],
        iniciadaEm: (mapa['iniciadaEm'] as Timestamp?)?.toDate(),
        aoVivo: mapa['aoVivo'] ?? true,
        encerradaEm: (mapa['encerradaEm'] as Timestamp?)?.toDate(),
        duracaoSegundos: mapa['duracaoSegundos'],
        vodUrl: mapa['vodUrl'],
      );
    }
    return const PostPlataformaAoVivo(link: '');
  }
}

/// Uma opcao de resposta dentro de uma postagem do tipo "enquete".
class PostOpcaoEnquete {
  final String texto;
  final int votos;

  const PostOpcaoEnquete({required this.texto, this.votos = 0});

  factory PostOpcaoEnquete.fromMap(Map<String, dynamic> data) {
    return PostOpcaoEnquete(
      texto: data['texto'] ?? '',
      votos: data['votos'] ?? 0,
    );
  }
}

/// Postagem do feed (Home). Suporta 4 tipos, diferenciados pelo campo [tipo]:
/// - avisoTexto: aviso com somente texto.
/// - aoVivo: aviso de que o canal esta ao vivo (com plataformas/link).
/// - avisoFoto: aviso com texto + foto.
/// - enquete: enquete com titulo (pergunta) e opcoes de resposta.
class PostModel {
  static const tipoAvisoTexto = 'avisoTexto';
  static const tipoAoVivo = 'aoVivo';
  static const tipoAvisoFoto = 'avisoFoto';
  static const tipoEnquete = 'enquete';

  static const List<String> tiposValidos = [tipoAvisoTexto, tipoAoVivo, tipoAvisoFoto, tipoEnquete];

  /// Peso de um post em destaque (admin e aviso de live) e de um post comum
  /// (demais cargos) na ordenacao do feed. Os mesmos numeros estao em
  /// `firestore.rules` (prioridadeDoCargo), que e quem de fato impede um
  /// inscrito de publicar com prioridade de admin - aqui e so leitura.
  static const int prioridadeDestaque = 100;
  static const int prioridadeComum = 0;

  static int prioridadeDoCargo(String cargo) => cargo == 'admin' ? prioridadeDestaque : prioridadeComum;

  /// Prioridade deduzida pra posts que nao tem o campo gravado:
  /// - avisos de live, escritos pelas Cloud Functions, sao do canal;
  /// - posts sem `autorCargo` nenhum sao os antigos, criados pelo admin
  ///   direto no Console antes de o painel existir.
  /// Em ambos os casos o lugar deles e no topo, junto com os do admin.
  static int prioridadePadrao({required String tipo, String? autorCargo}) {
    if (tipo == tipoAoVivo || autorCargo == null) return prioridadeDestaque;
    return prioridadeDoCargo(autorCargo);
  }

  /// Ordem do feed: primeiro a prioridade (post do admin/canal acima dos
  /// posts dos inscritos), depois o mais recente.
  ///
  /// A ordenacao e feita aqui, no cliente, e nao no `orderBy` do Firestore:
  /// ordenar por dois campos exigiria criar um indice composto no Console a
  /// mao, e o feed carrega poucas dezenas de posts - nao compensa.
  static List<PostModel> ordenarParaFeed(List<PostModel> posts) {
    final ordenados = [...posts];
    ordenados.sort((a, b) {
      final porPrioridade = b.prioridade.compareTo(a.prioridade);
      return porPrioridade != 0 ? porPrioridade : b.criadoEm.compareTo(a.criadoEm);
    });
    return ordenados;
  }

  final String id;
  final String tipo;
  final String autorUid;
  final String autorNickname;

  /// Cargo de quem publicou, congelado no momento da postagem ('inscrito',
  /// 'vip' ou 'admin'). Serve pra mostrar o selo no card sem precisar ler o
  /// perfil do autor de novo - e pra saber a [prioridade] do post.
  final String autorCargo;

  final DateTime criadoEm;
  final int curtidas;
  final int comentariosCount;

  /// Peso do post na ordenacao do feed: quanto maior, mais pra cima. Post
  /// de admin e aviso de live ficam acima dos posts dos inscritos (ver
  /// [prioridadeDoCargo] e [ordenarParaFeed]).
  final int prioridade;

  /// avisoTexto, aoVivo (legenda opcional) e avisoFoto (legenda).
  final String? texto;

  /// avisoFoto.
  final String? fotoUrl;

  /// aoVivo: uma entrada por plataforma ativa ('youtube', 'twitch', 'kick'),
  /// com link + dados extras (titulo/jogo/thumbnail) de cada uma.
  final Map<String, PostPlataformaAoVivo> plataformasAoVivo;

  /// enquete.
  final String? titulo;
  final List<PostOpcaoEnquete>? opcoes;

  /// enquete: uids de quem ja votou (evita votar mais de uma vez).
  final List<String> votantes;

  /// enquete: uid -> indice da opcao escolhida (pra destacar o botao certo).
  final Map<String, int> votosPorUsuario;

  const PostModel({
    required this.id,
    required this.tipo,
    required this.autorUid,
    required this.autorNickname,
    required this.criadoEm,
    this.autorCargo = 'inscrito',
    this.prioridade = 0,
    this.curtidas = 0,
    this.comentariosCount = 0,
    this.texto,
    this.fotoUrl,
    this.plataformasAoVivo = const {},
    this.titulo,
    this.opcoes,
    this.votantes = const [],
    this.votosPorUsuario = const {},
  });

  factory PostModel.fromFirestore(String id, Map<String, dynamic> data) {
    final tipo = data['tipo'] ?? tipoAvisoTexto;
    final autorCargo = data['autorCargo'] ?? 'inscrito';

    return PostModel(
      id: id,
      tipo: tipo,
      autorUid: data['autorUid'] ?? '',
      autorNickname: data['autorNickname'] ?? 'PTK Plays',
      autorCargo: autorCargo,
      // Posts criados antes desses campos existirem (Console do Firebase) e
      // os avisos de live escritos pelas Cloud Functions nao tem
      // 'prioridade' gravada - a deducao abaixo mantem os dois no topo,
      // sem precisar migrar nada no Firestore.
      prioridade: data['prioridade'] ?? prioridadePadrao(tipo: tipo, autorCargo: data['autorCargo']),
      criadoEm: (data['criadoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
      curtidas: data['curtidas'] ?? 0,
      comentariosCount: data['comentariosCount'] ?? 0,
      texto: data['texto'],
      fotoUrl: data['fotoUrl'],
      plataformasAoVivo: data['linksPorPlataforma'] is Map
          ? Map<String, dynamic>.from(data['linksPorPlataforma'] as Map).map(
              (plataforma, detalhes) => MapEntry(plataforma, PostPlataformaAoVivo.fromDynamic(detalhes)),
            )
          : const {},
      titulo: data['titulo'],
      opcoes: data['opcoes'] != null
          ? (data['opcoes'] as List).map((o) => PostOpcaoEnquete.fromMap(Map<String, dynamic>.from(o))).toList()
          : null,
      votantes: data['votantes'] != null ? List<String>.from(data['votantes']) : const [],
      votosPorUsuario: data['votosPorUsuario'] != null
          ? Map<String, int>.from(data['votosPorUsuario'])
          : const {},
    );
  }
}
