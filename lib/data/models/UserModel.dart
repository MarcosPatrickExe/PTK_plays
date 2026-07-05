import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  static const List<String> categoriasValidas = ['otaku', 'gamer', 'streamer', 'geek', 'outro'];
  static const List<String> statusValidos = ['online', 'invisivel', 'naoPerturbe', 'offline'];

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
  });

  factory UserModel.novoInscrito({
    required String uid,
    required String nickname,
    required String email,
    String fotoUrl = '',
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
      badges: const [],
      contadores: const {'comentarios': 0, 'curtidas': 0, 'cliquesLive': 0},
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
    };
  }

  /// Payload leve pra so atualizar a data de ultimo acesso (login),
  /// sem reenviar o documento inteiro. Use com SetOptions(merge: true).
  static Map<String, dynamic> touchUltimoAcesso() {
    return {'ultimoAcesso': FieldValue.serverTimestamp()};
  }
}
