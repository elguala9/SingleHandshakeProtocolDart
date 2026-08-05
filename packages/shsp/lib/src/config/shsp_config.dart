import 'package:config_manager/config_manager.dart';

/// The `config_manager` sector owned by this package.
const String shspConfigSector = 'shsp';

/// Key a larger JSON document can nest the SHSP section under, so a whole
/// multi-domain config blob can be handed to [initShspConfig] as-is instead
/// of extracting the SHSP part first.
const String shspConfigKey = 'ShspConfig';

/// Built-in SHSP defaults, also used as the fallback for missing keys and as
/// the source of valid configuration keys.
const Map<String, dynamic> defaultShspConfig = {
  'keepAliveSeconds': 30,
  'handshake': {'timeoutMs': 5000, 'intervalOfSendingHandshakeMs': 500},
  'retry': {
    'maxAttempts': 10,
    'initialDelayMs': 500,
    'backoffMultiplier': 1.5,
  },
};

/// Loads [defaultShspConfig] into [shspConfigSector], with [overrides]
/// deep-merged on top. [overrides] can be the SHSP fields directly, or a
/// bigger document nesting them under [shspConfigKey] — only that section is
/// used, so foreign JSON can be merged in and handed over as-is. Always
/// replaces whatever was loaded before; use [ensureShspConfig] to seed the
/// sector only if it's still empty.
void initShspConfig([Map<String, dynamic>? overrides]) {
  _access.loadFromMap(_merge(defaultShspConfig, unwrapShspConfig(overrides)));
}

/// The SHSP section of [map]: `map[shspConfigKey]` when present, or [map]
/// itself otherwise.
Map<String, dynamic>? unwrapShspConfig(Map<String, dynamic>? map) =>
    (map?[shspConfigKey] as Map<String, dynamic>?) ?? map;

/// Seeds [defaultShspConfig] into [shspConfigSector], but only if it isn't
/// already loaded.
void ensureShspConfig() {
  _access.loadFromMap(defaultShspConfig, force: false);
}

/// [ShspConfigExtension.defaultKeepAliveSeconds] for static contexts, e.g.
/// constructor default values that cannot mix in [ShspConfigExtension].
int defaultShspKeepAliveSeconds() => _access.defaultKeepAliveSeconds;

/// Backs the static-context helpers above with a real [ConfigExtension]
/// instance, instead of talking to [ConfigManagerSingleton] directly.
final _access = _ShspConfigAccess();

class _ShspConfigAccess with ConfigExtension, ShspConfigExtension {}

/// Configuration access for the SHSP components: pins the sector to
/// [shspConfigSector] and exposes the defaults already coerced to their Dart
/// types. Mix in on top of [ConfigExtension].
mixin ShspConfigExtension on ConfigExtension {
  String _sector = shspConfigSector;

  @override
  String get configSector => _sector;

  @override
  set configSector(String value) => _sector = value;

  int get defaultKeepAliveSeconds => _get<int>(const ['keepAliveSeconds']);

  int get defaultHandshakeTimeoutMs =>
      _get<int>(const ['handshake', 'timeoutMs']);

  int get defaultHandshakeIntervalMs =>
      _get<int>(const ['handshake', 'intervalOfSendingHandshakeMs']);

  int get defaultRetryMaxAttempts => _get<int>(const ['retry', 'maxAttempts']);

  int get defaultRetryInitialDelayMs =>
      _get<int>(const ['retry', 'initialDelayMs']);

  double get defaultRetryBackoffMultiplier =>
      _get<double>(const ['retry', 'backoffMultiplier']);

  /// Reads [path], falling back to its [defaultShspConfig] entry when the
  /// loaded configuration doesn't define it (e.g. a partial config loaded
  /// directly via [ConfigExtension.loadFromString]/[loadFromMap]).
  T _get<T>(List<String> path) {
    ensureShspConfig();
    return containsKeys([path])
        ? get<T>(path)
        : _lookup(defaultShspConfig, path) as T;
  }
}

/// Walks [map] following [path].
dynamic _lookup(Map<String, dynamic> map, List<String> path) {
  dynamic current = map;
  for (final part in path) {
    if (current is! Map<String, dynamic>) return null;
    current = current[part];
  }
  return current;
}

/// Deep-merges [overrides] onto a mutable copy of [base].
///
/// The copy matters: the stored map is mutated in place by
/// `ConfigManagerSingleton.set`, and [defaultShspConfig] is `const`.
Map<String, dynamic> _merge(
  Map<String, dynamic> base,
  Map<String, dynamic>? overrides,
) {
  final merged = <String, dynamic>{};
  for (final entry in base.entries) {
    final value = entry.value;
    merged[entry.key] = value is Map<String, dynamic>
        ? _merge(value, null)
        : value;
  }
  if (overrides == null) return merged;

  for (final entry in overrides.entries) {
    final existing = merged[entry.key];
    final value = entry.value;
    merged[entry.key] =
        existing is Map<String, dynamic> && value is Map<String, dynamic>
        ? _merge(existing, value)
        : value;
  }
  return merged;
}
