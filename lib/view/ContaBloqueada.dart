import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ptk_plays/data/models/BloqueioDaConta.dart';
import 'package:ptk_plays/i18n/Idioma.dart';

/// O aviso de conta banida/suspensa, mostrado **na tela de login**.
///
/// **Até 14/set isto era uma tela inteira desenhada POR CIMA do app**, com a
/// pessoa ainda logada por baixo. A ideia era boa por um motivo (uma
/// suspensão vencendo com o app aberto devolvia a pessoa exatamente onde
/// estava, sem perder navegação), mas o preço era alto: quem foi banido
/// continuava **dentro** do app, com sessão válida, só com uma cortina na
/// frente. Basta a cortina falhar em qualquer caminho pra pessoa estar
/// usando o app de novo.
///
/// Agora quem é bloqueado é **expulso** pro login, e o aviso vira este
/// modal. O que a conta perde é só a navegação — e quem está banido não tem
/// pra onde navegar mesmo.
///
/// **A conta do Firebase Auth continua existindo, e isso é o ponto**: é ela
/// que carrega o `uid` que aponta pro `users/{uid}` com o
/// `estadoModeracao`. Apagar o login de quem foi banido apagaria justamente
/// a memória do banimento — a pessoa criaria outra conta com o mesmo e-mail
/// e entraria limpa.
Future<void> mostrarModalContaBloqueada(BuildContext context, BloqueioDaConta bloqueio) {
  return showDialog<void>(
    context: context,
    // Sem toque fora pra fechar: a pessoa tem que ler por que não entrou.
    barrierDismissible: false,
    builder: (_) => _ModalContaBloqueada(bloqueio: bloqueio),
  );
}

const Color _corDeBloqueio = Color(0xFFE0264F);

class _ModalContaBloqueada extends StatelessWidget {
  final BloqueioDaConta bloqueio;

  const _ModalContaBloqueada({required this.bloqueio});

  @override
  Widget build(BuildContext context) {
    final motivo = bloqueio.motivo;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              bloqueio.banido ? Icons.block : Icons.pause_circle_outline,
              color: _corDeBloqueio,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              bloqueio.banido ? textos.bloqueioBanida : textos.bloqueioSuspensa,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              bloqueio.banido
                  ? textos.bloqueioBanidaTexto
                  : textos.bloqueioSuspensaTexto(formatarDataDoBloqueio(bloqueio.ate)),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.black54, height: 1.4),
            ),
            if (motivo != null && motivo.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x14000000),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  textos.bloqueioMotivo(motivo),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.black54),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              textos.bloqueioLeiaAsRegras,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.black38),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _corDeBloqueio,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                textos.bloqueioEntendi,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A data até quando a suspensão vale, no formato da língua da vez.
String formatarDataDoBloqueio(DateTime? data) {
  if (data == null) return textos.bloqueioDataFutura;

  final local = data.toLocal();
  return textos.dataDiaMesAnoHora(
    local.day.toString().padLeft(2, '0'),
    local.month.toString().padLeft(2, '0'),
    local.year.toString(),
    local.hour.toString().padLeft(2, '0'),
    local.minute.toString().padLeft(2, '0'),
  );
}
