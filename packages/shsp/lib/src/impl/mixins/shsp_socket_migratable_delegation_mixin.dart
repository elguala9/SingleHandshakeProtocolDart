import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../../interfaces/i_compression_codec.dart';
import '../../interfaces/socket/i_shsp_socket.dart';
import '../../types/callback_types.dart';
import '../../types/peer_types.dart';
import '../../types/socket_profile.dart';

mixin ShspSocketMigratableDelegationMixin implements IShspSocket {
  IShspSocket get delegateSocket;

  @override
  void applyProfile(ShspSocketProfile profile) =>
      delegateSocket.applyProfile(profile);

  @override
  void close() => delegateSocket.close();

  @override
  void destroy() => delegateSocket.destroy();

  @override
  ICompressionCodec get compressionCodec => delegateSocket.compressionCodec;

  @override
  ShspSocketProfile extractProfile() => delegateSocket.extractProfile();

  @override
  bool get isClosed => delegateSocket.isClosed;

  @override
  InternetAddress? get localAddress => delegateSocket.localAddress;

  @override
  int? get localPort => delegateSocket.localPort;

  @override
  CallbackOn get onClose => delegateSocket.onClose;

  @override
  CallbackOnError get onError => delegateSocket.onError;

  @override
  CallbackOn get onListening => delegateSocket.onListening;

  @override
  bool removeMessageCallback(PeerInfo peer, MessageCallbackFunction cb) =>
      delegateSocket.removeMessageCallback(peer, cb);

  @override
  int sendTo(List<int> buffer, PeerInfo peer) =>
      delegateSocket.sendTo(buffer, peer);

  @override
  String serializedObject() => delegateSocket.serializedObject();

  @override
  void setCloseCallback(void Function() cb) =>
      delegateSocket.setCloseCallback(cb);

  @override
  void setErrorCallback(void Function(dynamic err) cb) =>
      delegateSocket.setErrorCallback(cb);

  @override
  void setListeningCallback(void Function() cb) =>
      delegateSocket.setListeningCallback(cb);

  @override
  void setMessageCallback(PeerInfo peer, MessageCallbackFunction cb) =>
      delegateSocket.setMessageCallback(peer, cb);

  @override
  RawDatagramSocket get socket => delegateSocket.socket;

  @override
  InternetAddress get address => delegateSocket.address;

  @override
  int get port => delegateSocket.port;

  @override
  int send(List<int> buffer, InternetAddress address, int port) =>
      delegateSocket.send(buffer, address, port);

  @override
  Datagram? receive() => delegateSocket.receive();

  @override
  bool get broadcastEnabled => delegateSocket.broadcastEnabled;

  @override
  set broadcastEnabled(bool value) => delegateSocket.broadcastEnabled = value;

  @override
  bool get multicastLoopback => delegateSocket.multicastLoopback;

  @override
  set multicastLoopback(bool value) =>
      delegateSocket.multicastLoopback = value;

  @override
  int get multicastHops => delegateSocket.multicastHops;

  @override
  set multicastHops(int value) => delegateSocket.multicastHops = value;

  @override
  // ignore: deprecated_member_use
  NetworkInterface? get multicastInterface => delegateSocket.multicastInterface;

  @override
  set multicastInterface(NetworkInterface? value) =>
      // ignore: deprecated_member_use
      delegateSocket.multicastInterface = value;

  @override
  bool get readEventsEnabled => delegateSocket.readEventsEnabled;

  @override
  set readEventsEnabled(bool value) =>
      delegateSocket.readEventsEnabled = value;

  @override
  bool get writeEventsEnabled => delegateSocket.writeEventsEnabled;

  @override
  set writeEventsEnabled(bool value) =>
      delegateSocket.writeEventsEnabled = value;

  @override
  void joinMulticast(InternetAddress group, [NetworkInterface? interface]) =>
      delegateSocket.joinMulticast(group, interface);

  @override
  void leaveMulticast(InternetAddress group, [NetworkInterface? interface]) =>
      delegateSocket.leaveMulticast(group, interface);

  @override
  void setRawOption(RawSocketOption option) =>
      delegateSocket.setRawOption(option);

  @override
  Uint8List getRawOption(RawSocketOption option) =>
      delegateSocket.getRawOption(option);

  @override
  StreamSubscription<RawSocketEvent> listen(
    void Function(RawSocketEvent event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => delegateSocket.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  bool get isBroadcast => delegateSocket.isBroadcast;

  @override
  Stream<RawSocketEvent> asBroadcastStream({
    void Function(StreamSubscription<RawSocketEvent>)? onListen,
    void Function(StreamSubscription<RawSocketEvent>)? onCancel,
  }) => delegateSocket.asBroadcastStream(
    onListen: onListen,
    onCancel: onCancel,
  );

  @override
  Stream<RawSocketEvent> where(bool Function(RawSocketEvent) test) =>
      delegateSocket.where(test);

  @override
  Stream<S> map<S>(S Function(RawSocketEvent) convert) =>
      delegateSocket.map(convert);

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(RawSocketEvent) convert) =>
      delegateSocket.asyncMap(convert);

  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(RawSocketEvent) convert) =>
      delegateSocket.asyncExpand(convert);

  @override
  Stream<S> expand<S>(Iterable<S> Function(RawSocketEvent) convert) =>
      delegateSocket.expand(convert);

  @override
  Stream<RawSocketEvent> handleError(
    Function onError, {
    bool Function(dynamic)? test,
  }) => delegateSocket.handleError(onError, test: test);

  @override
  Stream<S> transform<S>(
    StreamTransformer<RawSocketEvent, S> streamTransformer,
  ) => delegateSocket.transform(streamTransformer);

  @override
  Future<RawSocketEvent> reduce(
    RawSocketEvent Function(RawSocketEvent, RawSocketEvent) combine,
  ) => delegateSocket.reduce(combine);

  @override
  Future<T> fold<T>(
    T initialValue,
    T Function(T, RawSocketEvent) combine,
  ) => delegateSocket.fold(initialValue, combine);

  @override
  Future<String> join([String separator = '']) =>
      delegateSocket.join(separator);

  @override
  Future<bool> any(bool Function(RawSocketEvent) test) =>
      delegateSocket.any(test);

  @override
  Future<bool> every(bool Function(RawSocketEvent) test) =>
      delegateSocket.every(test);

  @override
  Future<int> get length => delegateSocket.length;

  @override
  Future<bool> get isEmpty => delegateSocket.isEmpty;

  @override
  Future<List<RawSocketEvent>> toList() => delegateSocket.toList();

  @override
  Future<Set<RawSocketEvent>> toSet() => delegateSocket.toSet();

  @override
  Future<E> drain<E>([E? futureValue]) => delegateSocket.drain(futureValue);

  @override
  Stream<RawSocketEvent> take(int count) => delegateSocket.take(count);

  @override
  Stream<RawSocketEvent> takeWhile(bool Function(RawSocketEvent) test) =>
      delegateSocket.takeWhile(test);

  @override
  Stream<RawSocketEvent> skip(int count) => delegateSocket.skip(count);

  @override
  Stream<RawSocketEvent> skipWhile(bool Function(RawSocketEvent) test) =>
      delegateSocket.skipWhile(test);

  @override
  Stream<RawSocketEvent> distinct([
    bool Function(RawSocketEvent, RawSocketEvent)? equals,
  ]) => delegateSocket.distinct(equals);

  @override
  Future<RawSocketEvent> get first => delegateSocket.first;

  @override
  Future<RawSocketEvent> get last => delegateSocket.last;

  @override
  Future<RawSocketEvent> get single => delegateSocket.single;

  @override
  Future<RawSocketEvent> firstWhere(
    bool Function(RawSocketEvent) test, {
    RawSocketEvent Function()? orElse,
  }) => delegateSocket.firstWhere(test, orElse: orElse);

  @override
  Future<RawSocketEvent> lastWhere(
    bool Function(RawSocketEvent) test, {
    RawSocketEvent Function()? orElse,
  }) => delegateSocket.lastWhere(test, orElse: orElse);

  @override
  Future<RawSocketEvent> singleWhere(
    bool Function(RawSocketEvent) test, {
    RawSocketEvent Function()? orElse,
  }) => delegateSocket.singleWhere(test, orElse: orElse);

  @override
  Future<RawSocketEvent> elementAt(int index) =>
      delegateSocket.elementAt(index);

  @override
  Stream<RawSocketEvent> timeout(
    Duration timeLimit, {
    void Function(EventSink<RawSocketEvent>)? onTimeout,
  }) => delegateSocket.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<bool> contains(Object? needle) => delegateSocket.contains(needle);

  @override
  Future<void> forEach(void Function(RawSocketEvent) action) =>
      delegateSocket.forEach(action);

  @override
  Stream<R> cast<R>() => delegateSocket.cast<R>();

  @override
  Future<void> pipe(StreamConsumer<RawSocketEvent> streamConsumer) =>
      delegateSocket.pipe(streamConsumer);
}
