import 'remote_config.dart';

abstract class RemoteConfigRepository {
  /// Current snapshot — synchronous, always available.
  RemoteConfig current();

  /// Force a fetch from the admin API.
  Future<void> refresh();

  /// Emits a fresh snapshot whenever the catalog is reloaded.
  Stream<RemoteConfig> watch();
}
