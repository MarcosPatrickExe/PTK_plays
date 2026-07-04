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

}
