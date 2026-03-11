
import 'package:shsp/shsp.dart';
import 'package:shsp/src/impl/registry/registry_utility.dart';

enum SocketType {
  ipv4(4),
  ipv6(6);

  final int value;

  const SocketType(this.value);
}

typedef RegistrySingletonShspSocket = RegistrySingleton<SocketType, IShspSocket>;

typedef RegistrySingletonShspPeer<Key> = RegistrySingleton<Key, IShspPeer>;
