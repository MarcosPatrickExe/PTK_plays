// Testa o campo telefoneWhatsapp adicionado ao UserModel (cadastro opcional
// de WhatsApp, ver lib/view/Cadastro.dart e ROADMAP.md).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/data/models/UserModel.dart';

void main() {
  group('UserModel.telefoneWhatsapp', () {
    test('novoInscrito sem telefone assume string vazia por padrao', () {
      final user = UserModel.novoInscrito(uid: 'u1', nickname: 'Fulano', email: 'fulano@teste.com');
      expect(user.telefoneWhatsapp, '');
    });

    test('novoInscrito preserva o telefone informado', () {
      final user = UserModel.novoInscrito(
        uid: 'u1',
        nickname: 'Fulano',
        email: 'fulano@teste.com',
        telefoneWhatsapp: '11999998888',
      );
      expect(user.telefoneWhatsapp, '11999998888');
    });

    test('toFirestore inclui telefoneWhatsapp no payload', () {
      final user = UserModel.novoInscrito(
        uid: 'u1',
        nickname: 'Fulano',
        email: 'fulano@teste.com',
        telefoneWhatsapp: '11999998888',
      );
      expect(user.toFirestore()['telefoneWhatsapp'], '11999998888');
    });

    test('fromFirestore le o telefoneWhatsapp gravado', () {
      final data = {
        'uid': 'u1',
        'nickname': 'Fulano',
        'email': 'fulano@teste.com',
        'cargo': 'inscrito',
        'status': 'online',
        'criadoEm': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'telefoneWhatsapp': '11999998888',
      };
      expect(UserModel.fromFirestore(data).telefoneWhatsapp, '11999998888');
    });

    test('fromFirestore assume vazio para contas antigas sem o campo', () {
      final data = {
        'uid': 'u1',
        'nickname': 'Fulano',
        'email': 'fulano@teste.com',
        'cargo': 'inscrito',
        'status': 'online',
        'criadoEm': Timestamp.fromDate(DateTime(2026, 1, 1)),
      };
      expect(UserModel.fromFirestore(data).telefoneWhatsapp, '');
    });
  });

  group('UserModel.badges', () {
    test('novoInscrito ja vem com a badge novato (gamificacao)', () {
      final user = UserModel.novoInscrito(uid: 'u1', nickname: 'Fulano', email: 'fulano@teste.com');
      expect(user.badges, ['novato']);
    });
  });

  group('UserModel.avatarPreset', () {
    test('novoInscrito sem avatar assume string vazia por padrao', () {
      final user = UserModel.novoInscrito(uid: 'u1', nickname: 'Fulano', email: 'fulano@teste.com');
      expect(user.avatarPreset, '');
    });

    test('novoInscrito preserva o avatar escolhido', () {
      final user = UserModel.novoInscrito(
        uid: 'u1',
        nickname: 'Fulano',
        email: 'fulano@teste.com',
        avatarPreset: 'otaku',
      );
      expect(user.avatarPreset, 'otaku');
    });

    test('toFirestore inclui avatarPreset no payload', () {
      final user = UserModel.novoInscrito(
        uid: 'u1',
        nickname: 'Fulano',
        email: 'fulano@teste.com',
        avatarPreset: 'gamer',
      );
      expect(user.toFirestore()['avatarPreset'], 'gamer');
    });

    test('fromFirestore le o avatarPreset gravado', () {
      final data = {
        'uid': 'u1',
        'nickname': 'Fulano',
        'email': 'fulano@teste.com',
        'cargo': 'inscrito',
        'status': 'online',
        'criadoEm': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'avatarPreset': 'streamer',
      };
      expect(UserModel.fromFirestore(data).avatarPreset, 'streamer');
    });

    test('fromFirestore assume vazio para contas antigas sem o campo', () {
      final data = {
        'uid': 'u1',
        'nickname': 'Fulano',
        'email': 'fulano@teste.com',
        'cargo': 'inscrito',
        'status': 'online',
        'criadoEm': Timestamp.fromDate(DateTime(2026, 1, 1)),
      };
      expect(UserModel.fromFirestore(data).avatarPreset, '');
    });
  });
}
