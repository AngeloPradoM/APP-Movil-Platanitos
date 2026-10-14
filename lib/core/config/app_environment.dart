enum AppMode { demo, remote }

abstract final class AppEnvironment {
  static const _configuredMode = String.fromEnvironment(
    'APP_MODE',
    defaultValue: 'demo',
  );

  static AppMode get mode =>
      _configuredMode.toLowerCase() == 'remote' ? AppMode.remote : AppMode.demo;

  static bool get isDemo => mode == AppMode.demo;
}
