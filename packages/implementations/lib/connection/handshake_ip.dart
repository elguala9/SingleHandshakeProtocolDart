import 'dart:io';
import 'package:shsp_types/shsp_types.dart';
import 'package:stun/stun.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';

typedef InputHandshakeIP = ({
  PeerInfo? publicIPv4,
  PeerInfo? publicIPv6,
  PeerInfo? localIPv4,
  PeerInfo? localIPv6,
});

class HandshakeIP implements IHandshakeIP {
  PeerInfo? publicIPv4;
  PeerInfo? publicIPv6;
  PeerInfo? localIPv4;
  PeerInfo? localIPv6;

  HandshakeIP(InputHandshakeIP input)
      : publicIPv4 = input.publicIPv4,
        publicIPv6 = input.publicIPv6,
        localIPv4 = input.localIPv4,
        localIPv6 = input.localIPv6;

  HandshakeIP._iPv6(this.publicIPv6, this.localIPv6);

  HandshakeIP._iPv4(this.publicIPv4, this.localIPv4);

  static Future<HandshakeIP> createAsync(RawDatagramSocket socket) async {
    // Configure STUN handler
    final input = (
      address: null,
      port: null,
      socket: socket,
    );
    final handler = StunHandler(input);
    final local = await handler.performLocalRequest();
    final public = await handler.performStunRequest();
    if (socket.address.type == InternetAddressType.IPv4) {
      return HandshakeIP._iPv4(
        PeerInfo(
            address: InternetAddress(public.publicIp), port: public.publicPort),
        PeerInfo(
            address: InternetAddress(local.localIp), port: local.localPort),
      );
    } else {
      return HandshakeIP._iPv6(
        PeerInfo(
            address: InternetAddress(public.publicIp), port: public.publicPort),
        PeerInfo(
            address: InternetAddress(local.localIp), port: local.localPort),
      );
    }
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
