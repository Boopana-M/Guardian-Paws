class AppConfig {
  // Back4App Configuration
  static const String appId = String.fromEnvironment(
    'PARSE_APP_ID',
    defaultValue: 'S0S2uABIu4e04c1PZZlvfnRqoXQMhaA8A8lpxv3K',
  );
  static const String clientKey = String.fromEnvironment(
    'PARSE_CLIENT_KEY',
    defaultValue: '3LN0lVzUUbarSBITRSu8DXGOhH4IYnPq04NrE08a',
  );
  static const String serverUrl = String.fromEnvironment(
    'PARSE_SERVER_URL',
    defaultValue: 'https://parseapi.back4app.com',
  );
}
