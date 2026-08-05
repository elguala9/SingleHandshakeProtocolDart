import 'package:config_manager/config_manager.dart';

/// The `config_manager` sector owned by this package.
const String shspConfigSector = 'shsp';

/// Key nesting the actual SHSP settings, both in [defaultShspConfig] and in
/// any [overrides] handed to [initShspConfig] — so a larger multi-domain
/// JSON document can carry this section as-is instead of extracting it
/// first.
const String shspConfigKey = 'shspConfig';

/// Built-in SHSP defaults, also used as the fallback for missing keys and as
/// the source of valid configuration keys.
const Map<String, dynamic> defaultShspConfig = {
  shspConfigKey: {
    'keepAliveSeconds': 30,
    'handshake': {'timeoutMs': 5000, 'intervalOfSendingHandshakeMs': 500},
    'retry': {
      'maxAttempts': 10,
      'initialDelayMs': 500,
      'backoffMultiplier': 1.5,
    },
  },
};

/// Loads [defaultShspConfig] into [shspConfigSector], with [overrides]
/// deep-merged on top ([loadFromMap] already deep-merges). [overrides] can
/// be the SHSP fields directly, or a bigger document nesting them under
/// [shspConfigKey] — only that section is used, so foreign JSON can be
/// merged in and handed over as-is. Always replaces whatever was loaded
/// before. Not required before reading values: [ShspConfigExtension]'s
/// getters fall back to [defaultShspConfig] via `getOrDefault` regardless.
void initShspConfig([Map<String, dynamic>? overrides]) {
  _access.loadFromMap(defaultShspConfig);
  final section = unwrapShspConfig(overrides);
  if (section != null) {
    _access.loadFromMap({shspConfigKey: section});
  }
}

/// The SHSP section of [map]: `map[shspConfigKey]` when present, or [map]
/// itself otherwise.
Map<String, dynamic>? unwrapShspConfig(Map<String, dynamic>? map) =>
    (map?[shspConfigKey] as Map<String, dynamic>?) ?? map;

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

  int get defaultKeepAliveSeconds =>
      getOrDefault<int>(const [shspConfigKey, 'keepAliveSeconds'], defaultShspConfig);

  int get defaultHandshakeTimeoutMs => getOrDefault<int>(
    const [shspConfigKey, 'handshake', 'timeoutMs'],
    defaultShspConfig,
  );

  int get defaultHandshakeIntervalMs => getOrDefault<int>(
    const [shspConfigKey, 'handshake', 'intervalOfSendingHandshakeMs'],
    defaultShspConfig,
  );

  int get defaultRetryMaxAttempts => getOrDefault<int>(
    const [shspConfigKey, 'retry', 'maxAttempts'],
    defaultShspConfig,
  );

  int get defaultRetryInitialDelayMs => getOrDefault<int>(
    const [shspConfigKey, 'retry', 'initialDelayMs'],
    defaultShspConfig,
  );

  double get defaultRetryBackoffMultiplier => getOrDefault<double>(
    const [shspConfigKey, 'retry', 'backoffMultiplier'],
    defaultShspConfig,
  );
}
