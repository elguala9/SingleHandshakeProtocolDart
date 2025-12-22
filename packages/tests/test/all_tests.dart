import 'package:test/test.dart';

// Import all test files
import 'shsp_test.dart' as shsp_test;
import 'shsp_instance_test.dart' as shsp_instance_test;
import 'shsp_peer_test.dart' as shsp_peer_test;
import 'shsp_socket_test.dart' as shsp_socket_test;
import 'stun_handler_test.dart' as stun_handler_test;
import 'handshake_ip_test.dart' as handshake_ip_test;
import 'handshake_ownership_test.dart' as handshake_ownership_test;
import 'handshake_time_test.dart' as handshake_time_test;
import 'handshake_initiator_signal_handler_test.dart' as handshake_initiator_signal_handler_test;

// Utility tests
import 'utility/address_utility_test.dart' as address_utility_test;
import 'utility/callback_map_test.dart' as callback_map_test;
import 'utility/concat_utility_test.dart' as concat_utility_test;
import 'utility/message_callback_map_test.dart' as message_callback_map_test;

// Type tests
import 'types/peer_types_test.dart' as peer_types_test;
import 'types/remote_info_test.dart' as remote_info_test;
import 'types/stun_types_test.dart' as stun_types_test;

void main() {
  group('SHSP Tests', () {
    group('Core Implementation Tests', () {
      shsp_test.main();
      shsp_instance_test.main();
      shsp_peer_test.main();
      shsp_socket_test.main();
      stun_handler_test.main();
    });

    group('Handshake Tests', () {
      handshake_ip_test.main();
      handshake_ownership_test.main();
      handshake_time_test.main();
      handshake_initiator_signal_handler_test.main();
    });

    group('Utility Tests', () {
      address_utility_test.main();
      callback_map_test.main();
      concat_utility_test.main();
      message_callback_map_test.main();
    });

    group('Type Tests', () {
      peer_types_test.main();
      remote_info_test.main();
      stun_types_test.main();
    });
  });
}