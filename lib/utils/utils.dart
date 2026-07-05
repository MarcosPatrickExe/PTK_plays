import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Utils {

  static String get APIkey {
    if (kIsWeb) {
      return dotenv.env['YT_API_KEY_WEB'] ?? '';
    } else if (Platform.isAndroid) {
      return dotenv.env['YT_API_KEY_ANDROID'] ?? '';
    } else if (Platform.isIOS) {
      return dotenv.env['YT_API_KEY_IOS'] ?? '';
    }
    return '';
  }

  static const String channelID = "UCB0Xu_75SQQIHVjaTmGBYuQ";

  static const String androidPackageName = "com.ptksolucoesdigitais.ptk_plays";
  static const String iosBundleId = "com.ptksolucoesdigitais.ptk_plays";

  /// Headers que identificam o app pra chave da API restrita por plataforma no Google Cloud Console.
  static Map<String, String> get apiHeaders {
    if (kIsWeb) {
      return {};
    } else if (Platform.isAndroid) {
      return {
        'X-Android-Package': androidPackageName,
        'X-Android-Cert': dotenv.env['ANDROID_CERT_SHA1'] ?? '',
      };
    } else if (Platform.isIOS) {
      return {
        'X-Ios-Bundle-Identifier': iosBundleId,
      };
    }
    return {};
  }

}
