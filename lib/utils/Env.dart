/// Variaveis de ambiente injetadas em tempo de compilacao via
/// `--dart-define-from-file` (dev local) ou `--dart-define` (Vercel/CI).
/// Nao dependem de nenhum arquivo empacotado no build, entao funcionam
/// igual em debug, release e Flutter Web sem expor segredos como asset
/// publico.
class Env {
  static const String ytApiKeyWeb = String.fromEnvironment('YT_API_KEY_WEB');
  static const String ytApiKeyAndroid = String.fromEnvironment('YT_API_KEY_ANDROID');
  static const String ytApiKeyIos = String.fromEnvironment('YT_API_KEY_IOS');
  static const String androidCertSha1 = String.fromEnvironment('ANDROID_CERT_SHA1');
}
