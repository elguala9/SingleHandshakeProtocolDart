import 'package:callback_handler/callback_handler.dart';
import 'package:shsp/shsp.dart';
import 'package:test/test.dart';

/// NAT simulation for testing protocol behavior through different NAT types
class NatSimulator {

  NatSimulator(this.type);
  final String type; // 'fullCone', 'addressRestricted'
  final Map<String, dynamic> natMappings = {};
  final Set<String> allowedPeers = {};

  /// Record that internal IP:port is mapped to external IP:port
  void mapInternalToExternal(String internalAddr, String externalAddr) {
    natMappings[internalAddr] = externalAddr;
  }

  /// Extract IP address from 'IP:port' string
  String _extractIP(String address) => address.split(':').first;

  /// Check if incoming packet from peer should be allowed through NAT
  bool canReceivePacket(String fromPeer, String originalDestination) {
    switch (type) {
      case 'fullCone':
        // Full Cone: any external host can send to the mapped port
        return true;

      case 'addressRestricted':
        // Address-Restricted: only hosts that received packets from can send back
        // Restriction is on IP address only, not port
        return allowedPeers.contains(_extractIP(fromPeer));

      default:
        return false;
    }
  }

  /// Record that packet was sent to peer (opens NAT for responses)
  void recordOutgoingPacket(String toPeer, String originalDestination) {
    switch (type) {
      case 'addressRestricted':
        // Only track the IP, not the port
        allowedPeers.add(_extractIP(toPeer));
        break;
      case 'fullCone':
        // No restriction needed
        break;
    }
  }
}

/// Mock SHSP instance with NAT simulation
class NatAwareMockShspInstance implements IShspInstance {
  NatAwareMockShspInstance({
    required this.natSimulator,
    this.initialOpen = false,
    this.localAddress = '192.168.1.100:5000',
    this.externalAddress = '203.0.113.1:45000',
    this.targetPeer = '203.0.113.2:5000',
  }) {
    onHandshake = CallbackHandler<void, void>();
    onOpen = CallbackHandler<void, void>();
    onClosing = CallbackHandler<void, void>();
    onClose = CallbackHandler<void, void>();
    _messageCallback = CallbackHandler<PeerInfo, void>();
    natSimulator.mapInternalToExternal(localAddress, externalAddress);
  }

  final NatSimulator natSimulator;
  final String localAddress;
  final String externalAddress;
  final String targetPeer;
  final bool initialOpen;

  int handshakeSendCount = 0;
  int handshakeReceiveCount = 0;
  bool _handshakeState = false;
  bool _openState = false;
  late CallbackHandler<PeerInfo, void> _messageCallback;

  @override
  bool get handshake => _handshakeState;

  @override
  bool get open => _openState;

  @override
  bool get closing => false;

  @override
  int get keepAliveSeconds => 30;

  @override
  set keepAliveSeconds(int seconds) {}

  @override
  late CallbackHandler<void, void> onHandshake;

  @override
  late CallbackHandler<void, void> onOpen;

  @override
  late CallbackHandler<void, void> onClosing;

  @override
  late CallbackHandler<void, void> onClose;

  @override
  MessageCallback get messageCallback => _messageCallback;

  @override
  void sendHandshake() {
    handshakeSendCount++;
    // Record that we're sending a handshake to the target peer
    natSimulator.recordOutgoingPacket(targetPeer, externalAddress);
  }

  @override
  void keepAlive() {}

  @override
  void sendClosing() {}

  @override
  void sendClosed() {}

  @override
  void startKeepAlive() {}

  @override
  void stopKeepAlive() {}

  @override
  ShspInstanceProfile extractProfile() => const ShspInstanceProfile(
    keepAliveSeconds: 30,
    onHandshakeListeners: [],
    onOpenListeners: [],
    onClosingListeners: [],
    onCloseListeners: [],
    onMessageListeners: [],
  );

  @override
  void close() {}

  @override
  String serializedObject() => 'NatAwareMockShspInstance';

  @override
  void sendMessage(List<int> message) {}

  @override
  void onMessage(List<int> msg, PeerInfo info) {}

  @override
  void destroy() {}

  /// Simulate peer attempting to send handshake response
  /// Returns true if NAT allowed the packet through
  bool simulateHandshakeResponse(String fromPeer) {
    final allowed =
        natSimulator.canReceivePacket(fromPeer, externalAddress);

    if (allowed) {
      handshakeReceiveCount++;
      _handshakeState = true;
      _openState = true;
      onHandshake.call(null);
    }

    return allowed;
  }
}

void main() {
  group('SHSP NAT Simulation Tests', () {
    group('Full Cone NAT', () {
      test('allows handshake from any peer', () {
        final nat = NatSimulator('fullCone');
        final instance = NatAwareMockShspInstance(natSimulator: nat);

        instance.sendHandshake();
        expect(instance.handshakeSendCount, equals(1));

        // Any peer can respond
        final allowed1 = instance.simulateHandshakeResponse('10.0.0.1:5000');
        final allowed2 = instance.simulateHandshakeResponse('10.0.0.2:5000');

        expect(allowed1, isTrue);
        expect(allowed2, isTrue);
        expect(instance.handshakeReceiveCount, equals(2));
      });

      test('receives multiple handshakes through NAT', () {
        final nat = NatSimulator('fullCone');
        final instance = NatAwareMockShspInstance(natSimulator: nat);

        instance.sendHandshake();

        // Multiple unsolicited responses can get through
        for (int i = 0; i < 5; i++) {
          final allowed = instance
              .simulateHandshakeResponse('192.168.0.$i:${5000 + i}');
          expect(allowed, isTrue);
        }

        expect(instance.handshakeReceiveCount, equals(5));
      });
    });

    group('Address-Restricted Cone NAT', () {
      test(
          'only allows responses from peers that received outgoing handshake',
          () {
        final nat = NatSimulator('addressRestricted');
        final instance = NatAwareMockShspInstance(natSimulator: nat);

        // Before sending, unknown peer cannot respond
        final blockedBefore =
            instance.simulateHandshakeResponse('10.0.0.99:5000');
        expect(blockedBefore, isFalse);

        // Send handshake to peer
        instance.sendHandshake();

        // Now that target peer can respond (it's the one we sent to)
        final allowed1 = instance.simulateHandshakeResponse(instance.targetPeer);
        expect(allowed1, isTrue);

        // Different peer still blocked
        final blocked =
            instance.simulateHandshakeResponse('10.0.0.99:5000');
        expect(blocked, isFalse);

        expect(instance.handshakeReceiveCount, equals(1));
      });

      test('restricts based on peer address only', () {
        final nat = NatSimulator('addressRestricted');
        final instance = NatAwareMockShspInstance(
          natSimulator: nat,
          targetPeer: '203.0.113.2:5000',
        );

        instance.sendHandshake();

        // Same peer address, different port - should be allowed (address-restricted only)
        final allowed1 = instance.simulateHandshakeResponse('203.0.113.2:5000');
        expect(allowed1, isTrue);

        final allowed2 = instance.simulateHandshakeResponse('203.0.113.2:6000');
        expect(allowed2, isTrue);

        expect(instance.handshakeReceiveCount, equals(2));
      });
    });

    group('NAT Impact on Handshake Retry', () {
      test(
          'Full Cone NAT allows handshake to succeed',
          () async {
        final nat = NatSimulator('fullCone');
        final instance = NatAwareMockShspInstance(natSimulator: nat);

        final retry = ShspHandshakeRetryHandler.startRetry(instance: instance);

        expect(instance.handshakeSendCount, equals(1));

        // With Full Cone, any external host can send through the NAT mapping
        instance.simulateHandshakeResponse('203.0.113.2:45000');

        await Future.delayed(const Duration(milliseconds: 50));

        expect(retry.isActive, isFalse);
        expect(instance.handshakeReceiveCount, equals(1));
      });

      test(
          'Address-Restricted NAT works if handshake sent first',
          () async {
        final nat = NatSimulator('addressRestricted');
        final instance = NatAwareMockShspInstance(
          natSimulator: nat,
          targetPeer: '203.0.113.2:45000',
        );

        ShspHandshakeRetryHandler.startRetry(instance: instance);

        // Handshake must be sent first to open NAT for responses
        instance.simulateHandshakeResponse(instance.targetPeer);

        await Future.delayed(const Duration(milliseconds: 50));

        expect(instance.handshakeReceiveCount, equals(1));
      });
    });
  });
}
