import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  static const List<String> categoriasValidas = ['otaku', 'gamer', 'streamer', 'geek', 'outro'];
  static const List<String> statusValidos = ['online', 'invisivel', 'naoPerturbe', 'offline'];
  // 'vip' e 'admin' sao atribuidos manualmente (Console/painel), nunca no cadastro.
  static const List<String> cargosValidos = ['inscrito', 'vip', 'admin'];

  final String uid;
  final String nickname;
  final String email;
  final String fotoUrl;
  final String cargo;
  final List<String> categorias;
  final String status;
  final DateTime criadoEm;
  final DateTime? ultimoAcesso;
  final List<String> badges;
  final Map<String, int> contadores;
  // Opcional: usuario informa no cadastro se quiser (futuramente usado pra
  // notificacoes/recuperacao de conta/2FA via WhatsApp Business API).
  final String telefoneWhatsapp;
  // Chave de um dos avatares pre-definidos (ver AvatarPreset.dart), escolhido
  // no cadastro e trocavel na edicao de perfil. Vazio = sem preset escolhido
  // (contas criadas antes desse campo existir, ou login social ainda sem
  // escolha), caindo no fallback de fotoUrl/icone generico na UI.
  final String avatarPreset;

  const UserModel({
    required this.uid,
    required this.nickname,
    required this.email,
    required this.fotoUrl,
    required this.cargo,
    required this.categorias,
    required this.status,
    required this.criadoEm,
    required this.ultimoAcesso,
    required this.badges,
    required this.contadores,
    this.telefoneWhatsapp = '',
    this.avatarPreset = '',
  });

  factory UserModel.novoInscrito({
    required String uid,
    required String nickname,
    required String email,
    String fotoUrl = '',
    String telefoneWhatsapp = '',
    String avatarPreset = '',
  }) {
    return UserModel(
      uid: uid,
      nickname: nickname,
      email: email,
      fotoUrl: fotoUrl,
      cargo: 'inscrito',
      categorias: const [],
      status: 'online',
      criadoEm: DateTime.now(),
      ultimoAcesso: null,
      // Toda conta nova ja nasce com essa badge (gamificacao); qualquer outra
      // badge so pode ser concedida por um backend de confianca depois (ver
      // firestore.rules: 'badges' e travada contra update pelo cliente).
      badges: const ['novato'],
      contadores: const {'comentarios': 0, 'curtidas': 0, 'cliquesLive': 0},
      telefoneWhatsapp: telefoneWhatsapp,
      avatarPreset: avatarPreset,
    );
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      nickname: data['nickname'],
      email: data['email'],
      fotoUrl: data['fotoUrl'] ?? '',
      cargo: data['cargo'],
      categorias: List<String>.from(data['categorias'] ?? []),
      status: data['status'],
      criadoEm: (data['criadoEm'] as Timestamp).toDate(),
      ultimoAcesso: (data['ultimoAcesso'] as Timestamp?)?.toDate(),
      badges: List<String>.from(data['badges'] ?? []),
      contadores: Map<String, int>.from(data['contadores'] ?? {}),
      // Contas criadas antes desse campo existir nao tem essa chave no Firestore.
      telefoneWhatsapp: data['telefoneWhatsapp'] ?? '',
      avatarPreset: data['avatarPreset'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'nickname': nickname,
      'email': email,
      'fotoUrl': fotoUrl,
      'cargo': cargo,
      'categorias': categorias,
      'status': status,
      'criadoEm': Timestamp.fromDate(criadoEm),
      'ultimoAcesso': FieldValue.serverTimestamp(),
      'badges': badges,
      'contadores': contadores,
      'telefoneWhatsapp': telefoneWhatsapp,
      'avatarPreset': avatarPreset,
    };
  }

  /// Payload leve pra so atualizar a data de ultimo acesso (login),
  /// sem reenviar o documento inteiro. Use com SetOptions(merge: true).
  static Map<String, dynamic> touchUltimoAcesso() {
    return {'ultimoAcesso': FieldValue.serverTimestamp()};
  }
}
