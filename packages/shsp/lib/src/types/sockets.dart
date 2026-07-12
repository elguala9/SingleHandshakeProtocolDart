import 'dart:io';
import '../../shsp.dart';

class Sockets {
  Sockets({IShspSocket? ipv4SocketImpl, IShspSocket? ipv6SocketImpl}) {
    this.ipv4SocketImpl = ipv4SocketImpl;
    this.ipv6SocketImpl = ipv6SocketImpl;
  }

  IShspSocket? _ipv4SocketImpl;
  IShspSocket? _ipv6SocketImpl;

  IShspSocket? get ipv4SocketImpl => _ipv4SocketImpl;
  set ipv4SocketImpl(IShspSocket? value) {
    if (value != null) {
      final addr = value.localAddress;
      if (addr != null && addr.type != InternetAddressType.IPv4) {
        throw ArgumentError(
          'Provided IPv4 socket has address type ${addr.type}',
        );
      }
    }
    _ipv4SocketImpl = value;
  }

  IShspSocket? get ipv6SocketImpl => _ipv6SocketImpl;
  set ipv6SocketImpl(IShspSocket? value) {
    if (value != null) {
      final addr = value.localAddress;
      if (addr != null && addr.type != InternetAddressType.IPv6) {
        throw ArgumentError(
          'Provided IPv6 socket has address type ${addr.type}',
        );
      }
    }
    _ipv6SocketImpl = value;
  }
}