import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/MensagemWhatsapp.dart';

/// Leitura da caixa de entrada do WhatsApp, na aba WhatsApp do Painel ADM.
///
/// **Só leitura, e é de propósito.** A coleção `mensagensWhatsapp` é
/// escrita exclusivamente pelo webhook `whatsappWebhook`, que roda com o
/// Admin SDK; o `firestore.rules` trava a escrita pra todo cliente,
/// inclusive admin. Assim, nada que apareça aqui foi inventado pelo app —
/// ou a Meta entregou, ou não existe.
///
/// O envio de mensagens (a outra metade da aba) vai ser uma Cloud Function
/// chamada pelo app, não uma escrita direta nesta coleção, justamente pra
/// manter essa garantia.
class WhatsappRepository {
  final FirebaseFirestore _firestore;

  WhatsappRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String colecao = 'mensagensWhatsapp';

  /// As mensagens mais recentes, já agrupadas em conversas.
  ///
  /// O [limite] existe porque a caixa de entrada mostra conversas, não o
  /// histórico inteiro: 300 mensagens cobrem bastante conversa recente sem
  /// puxar a coleção toda a cada abertura da aba. Quando isso apertar, o
  /// caminho é paginar por conversa, não aumentar o número.
  Stream<List<ConversaWhatsapp>> streamConversas({int limite = 300}) {
    return _firestore
        .collection(colecao)
        .orderBy('atualizadaEm', descending: true)
        .limit(limite)
        .snapshots()
        .map((snap) => agruparEmConversas(
              snap.docs.map((doc) => MensagemWhatsapp.fromFirestore(doc.id, doc.data())).toList(),
            ));
  }
}
