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

  const PostPlataformaAoVivo({
    required this.link,
    this.titulo,
    this.jogo,
    this.thumbnailUrl,
    this.iniciadaEm,
  });

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

  final String id;
  final String tipo;
  final String autorUid;
  final String autorNickname;
  final DateTime criadoEm;
  final int curtidas;
  final int comentariosCount;

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
    return PostModel(
      id: id,
      tipo: data['tipo'] ?? tipoAvisoTexto,
      autorUid: data['autorUid'] ?? '',
      autorNickname: data['autorNickname'] ?? 'PTK Plays',
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
