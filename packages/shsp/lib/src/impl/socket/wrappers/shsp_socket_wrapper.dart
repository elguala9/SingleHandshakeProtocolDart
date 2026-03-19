import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../../../../shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

/// SHSP SocketWrapper: agisce come un proxy per permettere il cambio del socket
/// sottostante senza dover aggiornare i riferimenti in ogni ShspPeer.
class ShspSocketWrapper implements IShspSocket, IValueForRegistry {
  ShspSocketWrapper(this._socket);

  // Rimosso 'final' per permettere il cambio del riferimento del socket
  IShspSocket _socket;

  // Setter per aggiornare il socket interno
  set internalSocket(ShspSocket newSocket) => _socket = newSocket;

  // Computed getter: aggiornato automaticamente dopo ogni swap
  RawDatagramSocket get _raw => _socket.socket;

  // ── IShspSocket ────────────────────────────────────────────────────────────

  @override
  void applyProfile(ShspSocketProfile profile) => _socket.applyProfile(profile);

  @override
  void close() => _socket.close();

  @override
  void destroy() => _socket.destroy();

  @override
  ICompressionCodec get compressionCodec => _socket.compressionCodec;

  @override
  ShspSocketProfile extractProfile() => _socket.extractProfile();

  @override
  bool get isClosed => _socket.isClosed;

  @override
  InternetAddress? get localAddress => _socket.localAddress;

  @override
  int? get localPort => _socket.localPort;

  @override
  CallbackOn get onClose => _socket.onClose;

  @override
  CallbackOnError get onError => _socket.onError;

  @override
  CallbackOn get onListening => _socket.onListening;

  @override
  bool removeMessageCallback(PeerInfo peer, MessageCallbackFunction cb) =>
      _socket.removeMessageCallback(peer, cb);

  @override
  int sendTo(List<int> buffer, PeerInfo peer) => _socket.sendTo(buffer, peer);

  @override
  String serializedObject() => _socket.serializedObject();

  @override
  void setCloseCallback(void Function() cb) => _socket.setCloseCallback(cb);

  @override
  void setErrorCallback(void Function(dynamic err) cb) =>
      _socket.setErrorCallback(cb);

  @override
  void setListeningCallback(void Function() cb) =>
      _socket.setListeningCallback(cb);

  @override
  void setMessageCallback(PeerInfo peer, MessageCallbackFunction cb) =>
      _socket.setMessageCallback(peer, cb);

  @override
  RawDatagramSocket get socket => _raw;

  // ── RawDatagramSocket ──────────────────────────────────────────────────────

  @override
  InternetAddress get address => _raw.address;

  @override
  int get port => _raw.port;

  @override
  int send(List<int> buffer, InternetAddress address, int port) =>
      _raw.send(buffer, address, port);

  @override
  Datagram? receive() => _raw.receive();

  @override
  bool get broadcastEnabled => _raw.broadcastEnabled;
  @override
  set broadcastEnabled(bool value) => _raw.broadcastEnabled = value;

  @override
  bool get multicastLoopback => _raw.multicastLoopback;
  @override
  set multicastLoopback(bool value) => _raw.multicastLoopback = value;

  @override
  int get multicastHops => _raw.multicastHops;
  @override
  set multicastHops(int value) => _raw.multicastHops = value;

  @override
  // ignore: deprecated_member_use
  NetworkInterface? get multicastInterface => _raw.multicastInterface;
  @override
  set multicastInterface(NetworkInterface? value) =>
      // ignore: deprecated_member_use
      _raw.multicastInterface = value;

  @override
  bool get readEventsEnabled => _raw.readEventsEnabled;
  @override
  set readEventsEnabled(bool value) => _raw.readEventsEnabled = value;

  @override
  bool get writeEventsEnabled => _raw.writeEventsEnabled;
  @override
  set writeEventsEnabled(bool value) => _raw.writeEventsEnabled = value;

  @override
  void joinMulticast(InternetAddress group, [NetworkInterface? interface]) =>
      _raw.joinMulticast(group, interface);

  @override
  void leaveMulticast(InternetAddress group, [NetworkInterface? interface]) =>
      _raw.leaveMulticast(group, interface);

  @override
  void setRawOption(RawSocketOption option) => _raw.setRawOption(option);

  @override
  Uint8List getRawOption(RawSocketOption option) => _raw.getRawOption(option);

  // ── Stream<RawSocketEvent> ─────────────────────────────────────────────────

  @override
  StreamSubscription<RawSocketEvent> listen(
    void Function(RawSocketEvent event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _raw.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  bool get isBroadcast => _raw.isBroadcast;

  @override
  Stream<RawSocketEvent> asBroadcastStream({
    void Function(StreamSubscription<RawSocketEvent>)? onListen,
    void Function(StreamSubscription<RawSocketEvent>)? onCancel,
  }) => _raw.asBroadcastStream(onListen: onListen, onCancel: onCancel);

  @override
  Stream<RawSocketEvent> where(bool Function(RawSocketEvent) test) =>
      _raw.where(test);

  @override
  Stream<S> map<S>(S Function(RawSocketEvent) convert) => _raw.map(convert);

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(RawSocketEvent) convert) =>
      _raw.asyncMap(convert);

  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(RawSocketEvent) convert) =>
      _raw.asyncExpand(convert);

  @override
  Stream<S> expand<S>(Iterable<S> Function(RawSocketEvent) convert) =>
      _raw.expand(convert);

  @override
  Stream<RawSocketEvent> handleError(
    Function onError, {
    bool Function(dynamic)? test,
  }) => _raw.handleError(onError, test: test);

  @override
  Stream<S> transform<S>(
    StreamTransformer<RawSocketEvent, S> streamTransformer,
  ) => _raw.transform(streamTransformer);

  @override
  Future<RawSocketEvent> reduce(
    RawSocketEvent Function(RawSocketEvent, RawSocketEvent) combine,
  ) => _raw.reduce(combine);

  @override
  Future<T> fold<T>(T initialValue, T Function(T, RawSocketEvent) combine) =>
      _raw.fold(initialValue, combine);

  @override
  Future<String> join([String separator = '']) => _raw.join(separator);

  @override
  Future<bool> any(bool Function(RawSocketEvent) test) => _raw.any(test);

  @override
  Future<bool> every(bool Function(RawSocketEvent) test) => _raw.every(test);

  @override
  Future<int> get length => _raw.length;

  @override
  Future<bool> get isEmpty => _raw.isEmpty;

  @override
  Future<List<RawSocketEvent>> toList() => _raw.toList();

  @override
  Future<Set<RawSocketEvent>> toSet() => _raw.toSet();

  @override
  Future<E> drain<E>([E? futureValue]) => _raw.drain(futureValue);

  @override
  Stream<RawSocketEvent> take(int count) => _raw.take(count);

  @override
  Stream<RawSocketEvent> takeWhile(bool Function(RawSocketEvent) test) =>
      _raw.takeWhile(test);

  @override
  Stream<RawSocketEvent> skip(int count) => _raw.skip(count);

  @override
  Stream<RawSocketEvent> skipWhile(bool Function(RawSocketEvent) test) =>
      _raw.skipWhile(test);

  @override
  Stream<RawSocketEvent> distinct([
    bool Function(RawSocketEvent, RawSocketEvent)? equals,
  ]) => _raw.distinct(equals);

  @override
  Future<RawSocketEvent> get first => _raw.first;

  @override
  Future<RawSocketEvent> get last => _raw.last;

  @override
  Future<RawSocketEvent> get single => _raw.single;

  @override
  Future<RawSocketEvent> firstWhere(
    bool Function(RawSocketEvent) test, {
    RawSocketEvent Function()? orElse,
  }) => _raw.firstWhere(test, orElse: orElse);

  @override
  Future<RawSocketEvent> lastWhere(
    bool Function(RawSocketEvent) test, {
    RawSocketEvent Function()? orElse,
  }) => _raw.lastWhere(test, orElse: orElse);

  @override
  Future<RawSocketEvent> singleWhere(
    bool Function(RawSocketEvent) test, {
    RawSocketEvent Function()? orElse,
  }) => _raw.singleWhere(test, orElse: orElse);

  @override
  Future<RawSocketEvent> elementAt(int index) => _raw.elementAt(index);

  @override
  Stream<RawSocketEvent> timeout(
    Duration timeLimit, {
    void Function(EventSink<RawSocketEvent>)? onTimeout,
  }) => _raw.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<bool> contains(Object? needle) => _raw.contains(needle);

  @override
  Future<void> forEach(void Function(RawSocketEvent) action) =>
      _raw.forEach(action);

  @override
  Stream<R> cast<R>() => _raw.cast<R>();

  @override
  Future<void> pipe(StreamConsumer<RawSocketEvent> streamConsumer) =>
      _raw.pipe(streamConsumer);
}
