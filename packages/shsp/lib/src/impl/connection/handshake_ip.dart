import 'dart:io';
import '../../types/peer_types.dart';
import 'package:stun/stun.dart';
import '../../interfaces/connection/i_shsp_handshake.dart';
import '../socket/dual/dual_shsp_socket.dart';

typedef InputHandshakeIP = ({
  PeerInfo? publicIPv4,
  PeerInfo? publicIPv6,
  PeerInfo? localIPv4,
  PeerInfo? localIPv6,
});

class HandshakeIP implements IHandshakeIP {
  HandshakeIP(InputHandshakeIP input)
    : publicIPv4 = input.publicIPv4,
      publicIPv6 = input.publicIPv6,
      localIPv4 = input.localIPv4,
      localIPv6 = input.localIPv6;

  HandshakeIP._iPv6(this.publicIPv6, this.localIPv6)
    : publicIPv4 = null,
      localIPv4 = null;

  HandshakeIP._iPv4(this.publicIPv4, this.localIPv4)
    : publicIPv6 = null,
      localIPv6 = null;

  PeerInfo? publicIPv4;
  PeerInfo? publicIPv6;
  PeerInfo? localIPv4;
  PeerInfo? localIPv6;

  static Future<HandshakeIP> createAsync(RawDatagramSocket socket) async {
    // Configure STUN handler
    final input = (address: null, port: null, socket: socket);
    final handler = StunHandler(input);
    final local = await handler.performLocalRequest();
    final public = await handler.performStunRequest();
    if (socket.address.type == InternetAddressType.IPv4) {
      return HandshakeIP._iPv4(
        PeerInfo(
          address: InternetAddress(public.publicIp),
          port: public.publicPort,
        ),
        PeerInfo(
          address: InternetAddress(local.localIp),
          port: local.localPort,
        ),
      );
    } else {
      return HandshakeIP._iPv6(
        PeerInfo(
          address: InternetAddress(public.publicIp),
          port: public.publicPort,
        ),
        PeerInfo(
          address: InternetAddress(local.localIp),
          port: local.localPort,
        ),
      );
    }
  }

  /// Creates HandshakeIP with dual-stack support using both IPv4 and IPv6 sockets.
  ///
  /// This method performs STUN queries on both IPv4 and IPv6 sockets (if available)
  /// and populates all four address fields in the resulting HandshakeIP:
  /// - publicIPv4, localIPv4: from IPv4 socket STUN queries
  /// - publicIPv6, localIPv6: from IPv6 socket STUN queries (if socket is available)
  ///
  /// Parameters:
  ///   - [dualSocket]: The DualShspSocket containing IPv4 and optional IPv6 sockets
  ///
  /// Returns: A HandshakeIP with all available address fields populated
  static Future<HandshakeIP> createAsyncDual(DualShspSocket dualSocket) async {
    // Query IPv4 socket (always present)
    final ipv4RawSocket = dualSocket.ipv4Socket.socket;
    final ipv4Input = (address: null, port: null, socket: ipv4RawSocket);
    final ipv4Handler = StunHandler(ipv4Input);
    final ipv4Local = await ipv4Handler.performLocalRequest();
    final ipv4Public = await ipv4Handler.performStunRequest();

    final ipv4PublicPeer = PeerInfo(
      address: InternetAddress(ipv4Public.publicIp),
      port: ipv4Public.publicPort,
    );
    final ipv4LocalPeer = PeerInfo(
      address: InternetAddress(ipv4Local.localIp),
      port: ipv4Local.localPort,
    );

    // Query IPv6 socket if available
    PeerInfo? ipv6PublicPeer;
    PeerInfo? ipv6LocalPeer;

    if (dualSocket.ipv6Socket != null) {
      try {
        final ipv6RawSocket = dualSocket.ipv6Socket!.socket;
        final ipv6Input = (address: null, port: null, socket: ipv6RawSocket);
        final ipv6Handler = StunHandler(ipv6Input);
        final ipv6Local = await ipv6Handler.performLocalRequest();
        final ipv6Public = await ipv6Handler.performStunRequest();

        ipv6PublicPeer = PeerInfo(
          address: InternetAddress(ipv6Public.publicIp),
          port: ipv6Public.publicPort,
        );
        ipv6LocalPeer = PeerInfo(
          address: InternetAddress(ipv6Local.localIp),
          port: ipv6Local.localPort,
        );
      } catch (e) {
        // IPv6 STUN query failed, leave IPv6 addresses as null
        // This is not fatal - IPv4 addresses are still available
      }
    }

    return HandshakeIP((
      publicIPv4: ipv4PublicPeer,
      localIPv4: ipv4LocalPeer,
      publicIPv6: ipv6PublicPeer,
      localIPv6: ipv6LocalPeer,
    ));
  }

  @override
  PeerInfo? getPublicIPv4() => publicIPv4;
  @override
  PeerInfo? getPublicIPv6() => publicIPv6;
  @override
  PeerInfo? getLocalIPv4() => localIPv4;
  @override
  PeerInfo? getLocalIPv6() => localIPv6;
}
