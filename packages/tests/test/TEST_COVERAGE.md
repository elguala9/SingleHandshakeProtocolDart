# SHSP Test Suite

Test completo per tutte le interfacce e implementazioni del progetto Single HandShake Protocol.

## Test Creati

### Test Core Implementation
- **shsp_test.dart**: Test per la classe `Shsp` (implementazione di `IShsp`)
- **shsp_instance_test.dart**: Test esistente per `ShspInstance` 
- **shsp_peer_test.dart**: Test esistente per `ShspPeer`
- **shsp_socket_test.dart**: Test esistente per `ShspSocket`
- **stun_handler_test.dart**: Test per `StunHandler` (implementazione di `IStunHandler`)

### Test Handshake
- **handshake_ip_test.dart**: Test per `HandshakeIP` (implementazione di `IHandshakeIP`)
- **handshake_ownership_test.dart**: Test per `HandshakeOwnership` (implementazione di `IHandshakeOwnership`)
- **handshake_time_test.dart**: Test per `HandshakeTime` (implementazione di `IHandshakeTime`)
- **handshake_initiator_signal_handler_test.dart**: Test per le interfacce di segnalazione handshake

### Test Utility
- **address_utility_test.dart**: Test per `AddressUtility` (utility per formattazione indirizzi)
- **callback_map_test.dart**: Test per `CallbackMap<T>` (gestione callback generiche)
- **concat_utility_test.dart**: Test per `ConcatUtility` (utility per concatenazione dati)
- **message_callback_map_test.dart**: Test per `MessageCallbackMap` (gestione callback messaggi)

### Test Types
- **peer_types_test.dart**: Test per `PeerInfo`, `HandshakeSignal`, `SecuritySignal`
- **remote_info_test.dart**: Test per `RemoteInfo`
- **stun_types_test.dart**: Test per `StunResponse`, `LocalInfo`

## Struttura Test

```
packages/tests/test/
├── all_tests.dart                          # Test runner principale
├── shsp_test.dart                         # Test core Shsp
├── stun_handler_test.dart                 # Test STUN handler
├── handshake_ip_test.dart                # Test handshake IP
├── handshake_ownership_test.dart         # Test handshake ownership
├── handshake_time_test.dart              # Test handshake time
├── handshake_initiator_signal_handler_test.dart  # Test signal handler
├── utility/                              # Test utility
│   ├── address_utility_test.dart
│   ├── callback_map_test.dart
│   ├── concat_utility_test.dart
│   └── message_callback_map_test.dart
└── types/                                # Test types
    ├── peer_types_test.dart
    ├── remote_info_test.dart
    └── stun_types_test.dart
```

## Come Eseguire i Test

### Esegui tutti i test
```bash
cd packages/tests
dart test
```

### Esegui test specifici
```bash
# Test singolo file
dart test test/shsp_test.dart

# Test categoria specifica
dart test test/utility/
dart test test/types/

# Test runner completo
dart test test/all_tests.dart
```

### Esegui con coverage
```bash
dart test --coverage=coverage
dart pub global activate coverage
dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
```

## Copertura Test

I test coprono:

### ✅ Implementazioni Complete
- `Shsp` - Implementazione base IShsp
- `StunHandler` - Gestione STUN requests  
- `HandshakeIP` - Gestione indirizzi IP handshake
- `HandshakeOwnership` - Gestione ownership handshake
- `HandshakeTime` - Gestione timing handshake
- Tutte le utility classes

### ✅ Interfacce Testate
- `IShsp`
- `IStunHandler` 
- `IHandshakeIP`
- `IHandshakeOwnership`
- `IHandshakeTime`
- `IHandshakeInitiatorSignalHandler`

### ✅ Tipi Testati
- `PeerInfo` con serializzazione JSON
- `RemoteInfo` con serializzazione JSON
- `StunResponse` con gestione binary data
- `LocalInfo` 
- `HandshakeSignal` con tutti i campi
- `SecuritySignal`

### ✅ Scenari Coperti
- Serializzazione/deserializzazione JSON
- Gestione IPv4 e IPv6
- Gestione errori e casi limite
- Validazione parametri
- Round-trip conversions
- Gestione null values
- Performance con dati large

## Note Implementative

Alcuni test contengono sezioni commentate per funzionalità che richiedono:
- Connessioni di rete reali (STUN servers)
- Librerie esterne non disponibili in test environment
- Implementazioni async non complete

Questi sono documentati nei commenti per implementazione futura.

## Test Esistenti

I seguenti test erano già presenti:
- `shsp_instance_test.dart` - Test completo per ShspInstance
- `shsp_peer_test.dart` - Test completo per ShspPeer  
- `shsp_socket_test.dart` - Test completo per ShspSocket

Questi sono stati mantenuti intatti e integrati nel test runner.