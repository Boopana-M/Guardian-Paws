import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../config/app_config.dart';

class ParseService {
  static const String appId = AppConfig.appId;
  static const String clientKey = AppConfig.clientKey;
  static const String serverUrl = AppConfig.serverUrl;

  static Future<void> initialize() async {
    await Parse().initialize(
      appId,
      serverUrl,
      clientKey: clientKey,
      autoSendSessionId: true,
      debug: true,
    );
  }
}

