import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'Env.dart';

class Utils {

  static String get APIkey {
    if (kIsWeb) {
      return Env.ytApiKeyWeb;
    } else if (Platform.isAndroid) {
      return Env.ytApiKeyAndroid;
    } else if (Platform.isIOS) {
      return Env.ytApiKeyIos;
    }
    return '';
  }

  static const String channelID = "UCB0Xu_75SQQIHVjaTmGBYuQ";

  static const String androidPackageName = "com.ptksolucoesdigitais.ptk_plays";
  static const String iosBundleId = "com.ptksolucoesdigitais.ptkplays";

  /// Headers que identificam o app pra chave da API restrita por plataforma no Google Cloud Console.
  static Map<String, String> get apiHeaders {
    if (kIsWeb) {
      return {};
    } else if (Platform.isAndroid) {
      return {
        'X-Android-Package': androidPackageName,
        'X-Android-Cert': Env.androidCertSha1,
      };
    } else if (Platform.isIOS) {
      return {
        'X-Ios-Bundle-Identifier': iosBundleId,
      };
    }
    return {};
  }

}
