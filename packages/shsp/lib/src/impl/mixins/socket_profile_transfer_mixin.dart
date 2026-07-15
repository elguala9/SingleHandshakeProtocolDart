import 'dart:async';
import 'package:callback_handler/callback_handler.dart';
import 'package:meta/meta.dart';
import '../../interfaces/socket/i_shsp_socket_base.dart';
import '../../types/socket_profile.dart';

mixin SocketProfileTransferMixin<T extends IShspSocketBase> {
  T get socket;
  CallbackHandler<T, void> get socketChangedCallback;
  void replaceSocket(T newSocket);

  @protected
  Future<void> transferProfileAsync(
    Future<T> Function() buildNewSocket, {
    ShspSocketProfile? profile,
  }) async {
    final effectiveProfile = profile ?? socket.extractProfile();
    socket.close();
    final newSocket = await buildNewSocket();
    newSocket.applyProfile(effectiveProfile);
    replaceSocket(newSocket);
    socketChangedCallback(newSocket);
  }

  @protected
  void transferProfileSync(
    T Function() buildNewSocket, {
    ShspSocketProfile? profile,
  }) {
    final effectiveProfile = profile ?? socket.extractProfile();
    socket.close();
    final newSocket = buildNewSocket();
    newSocket.applyProfile(effectiveProfile);
    replaceSocket(newSocket);
    socketChangedCallback(newSocket);
  }
}
