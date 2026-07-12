import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:ptk_plays/services/LiveNotificationRouter.dart';

/// Notificacoes push de "PTK ao vivo". O app so escuta/inscreve no topico;
/// quem manda a notificacao e a Cloud Function `notificarAoVivo`, disparada
/// toda vez que um post do tipo "aoVivo" e criado no Firestore.
class NotificationService {
  NotificationService._();

  static const String _topicoAoVivo = 'ao_vivo';

  /// Chamar uma vez, logo depois do Firebase.initializeApp().
  ///
  /// So roda em Android/iOS: a Web precisaria de uma chave VAPID configurada
  /// no Firebase Console pra push funcionar, o que ainda nao foi feito.
  static Future<void> inicializar() async {
    if (kIsWeb) return;

    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.subscribeToTopic(_topicoAoVivo);

      // App em background e o usuario toca na notificacao (volta ao foreground).
      FirebaseMessaging.onMessageOpenedApp.listen(_tratarToqueNaNotificacao);

      // App estava fechado (terminated) e foi aberto tocando na notificacao.
      final mensagemInicial = await messaging.getInitialMessage();
      if (mensagemInicial != null) {
        _tratarToqueNaNotificacao(mensagemInicial);
      }
    } catch (e) {
      // Notificacao nao e essencial pro app funcionar; nunca deve derrubar o
      // app no startup se algo aqui falhar (ex: permissao negada).
      debugPrint('NotificationService: falha ao inicializar ($e)');
    }
  }

  static void _tratarToqueNaNotificacao(RemoteMessage mensagem) {
    final postId = mensagem.data['postId'];
    if (postId is String && postId.isNotEmpty) {
      LiveNotificationRouter.postIdParaDestacar.value = postId;
    }
  }
}
