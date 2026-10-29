enum AppMode { demo, remote }

abstract final class AppEnvironment {
  static const _configuredMode = String.fromEnvironment(
    'APP_MODE',
    defaultValue: 'remote',
  );

  static AppMode get mode =>
      _configuredMode.toLowerCase() == 'demo' ? AppMode.demo : AppMode.remote;

  static bool get isDemo => mode == AppMode.demo;
}
