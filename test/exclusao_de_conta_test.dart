import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/data/repositories/AuthRepository.dart';

void main() {
  group('formaParaProvedores', () {
    test('conta de e-mail/senha reautentica com senha', () {
      expect(formaParaProvedores(['password']), FormaDeReautenticar.senha);
    });

    test('conta só do Google reautentica pelo Google', () {
      // Era esta a conta que não conseguia se apagar até 14/set: o
      // excluirConta montava um EmailAuthProvider.credential com
      // `user.email!` e uma senha que não existe em lugar nenhum.
      expect(formaParaProvedores(['google.com']), FormaDeReautenticar.google);
    });

    test('conta só da Apple reautentica pela Apple', () {
      expect(formaParaProvedores(['apple.com']), FormaDeReautenticar.apple);
    });

    test('tendo senha E login social, a senha ganha', () {
      // Não é preferência estética: provar quem é pela senha não abre a
      // folha do provedor nem depende de rede externa na hora mais
      // delicada do fluxo. Abrir a folha quando não precisa é mais uma
      // chance de a exclusão falhar no meio.
      expect(formaParaProvedores(['google.com', 'password']), FormaDeReautenticar.senha);
      expect(formaParaProvedores(['apple.com', 'password']), FormaDeReautenticar.senha);
    });

    test('Apple ganha do Google quando os dois estão ligados', () {
      // A ordem importa pouco pra quem usa, mas a Apple exige revogar o
      // token dela ao apagar a conta (desde jun/2022). Passando pela
      // Apple, a revogação acontece; passando pelo Google, o app do PTK
      // continuaria listado nos ajustes do aparelho.
      expect(formaParaProvedores(['google.com', 'apple.com']), FormaDeReautenticar.apple);
    });

    test('lista vazia ou provedor desconhecido cai na senha', () {
      // Não é um acerto, é o caminho que o app sabe percorrer sozinho — e
      // o erro que vier dali diz o que houve, em vez de a tela travar sem
      // explicação.
      expect(formaParaProvedores([]), FormaDeReautenticar.senha);
      expect(formaParaProvedores(['facebook.com']), FormaDeReautenticar.senha);
    });
  });

  // O resto de excluirConta não tem teste automatizado aqui, e vale dizer
  // por quê: AuthRepository cria FirebaseAuth.instance, FirebaseFirestore
  // .instance e FirebaseStorage.instance nos próprios campos, então nada
  // dentro dele roda em `flutter test` — não há onde injetar um falso.
  //
  // O que precisa ser conferido à mão, num aparelho de verdade, com uma
  // conta descartável:
  //
  //  1. conta de e-mail/senha: apagar pede senha, some, e o app volta pro
  //     login;
  //  2. conta de Google: apagar abre a folha do Google e some;
  //  3. conta de Apple: idem, e o PTK Plays deixa de aparecer em Ajustes >
  //     Apple ID > Login com a Apple (essa parte depende da configuração de
  //     fluxo OAuth no Console — Team ID, Key ID e a chave .p8 — que ainda
  //     não foi feita; sem ela a revogação falha em silêncio e a exclusão
  //     segue assim mesmo, de propósito);
  //  4. depois de apagar, o nickname volta a estar livre pra outra conta;
  //  5. os posts da pessoa somem do feed pra todo mundo;
  //  6. numa enquete em que ela tinha votado, o total de votos continua o
  //     mesmo e o uid dela sumiu de `votantes`.
  //
  // Os itens 4, 5 e 6 dependem das regras novas em firestore.rules e
  // storage.rules ESTAREM PUBLICADAS. Sem publicar, a exclusão falha na
  // metade e a conta continua existindo — que é o comportamento desenhado
  // (falhar deixando a conta de pé, e não meio apagada), mas parece um bug
  // se ninguém souber que o deploy faltou.
}
