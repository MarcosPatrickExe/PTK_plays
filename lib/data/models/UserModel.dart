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
      'badges': badges,
      'contadores': contadores,
    };
  }
}
