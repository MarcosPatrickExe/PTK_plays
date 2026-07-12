import 'package:flutter/foundation.dart';

/// Ponte simples entre o tratamento de notificacoes (que roda fora da arvore
/// de widgets, em qualquer estado do app) e a tela de Feed. Quando o usuario
/// toca numa notificacao de "ao vivo", o id do post vai pra ca; a Home
/// escuta essa mudanca pra rolar ate o card certo e destaca-lo.
class LiveNotificationRouter {
  LiveNotificationRouter._();

  static final ValueNotifier<String?> postIdParaDestacar = ValueNotifier<String?>(null);
}
