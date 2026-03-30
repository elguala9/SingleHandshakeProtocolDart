import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:meta/meta.dart';
import '../../interfaces/utility/i_raw_shsp_socket.dart';

/// Hoping that in a future RawDatagramSocket (or similar) will become a real class (AS NOW THERE IS NOT OTHER OPTION BECAUSE RawDatagramSocket IS AN ABSTRACT CLASS)
class RawShspSocket implements IRawShspSocket {
  RawShspSocket(this.socket);

  @protected
  final RawDatagramSocket socket;

  // Forwarding for RawDatagramSocket
  @override
  int send(List<int> buffer, InternetAddress address, int port) =>
      socket.send(buffer, address, port);

  @override
  void close() => socket.close();

  @override
  InternetAddress get address => socket.address;

  @override
  int get port => socket.port;

  @override
  Datagram? receive() => socket.receive();

  @override
  bool get broadcastEnabled => socket.broadcastEnabled;
  @override
  set broadcastEnabled(bool value) => socket.broadcastEnabled = value;

  @override
  bool get multicastLoopback => socket.multicastLoopback;
  @override
  set multicastLoopback(bool value) => socket.multicastLoopback = value;

  @override
  void joinMulticast(InternetAddress group, [NetworkInterface? interface]) =>
      socket.joinMulticast(group, interface);

  @override
  void leaveMulticast(InternetAddress group, [NetworkInterface? interface]) =>
      socket.leaveMulticast(group, interface);

  @override
  void setRawOption(RawSocketOption option) => socket.setRawOption(option);

  @override
  Uint8List getRawOption(RawSocketOption option) => socket.getRawOption(option);

  @override
  bool get readEventsEnabled => socket.readEventsEnabled;
  @override
  set readEventsEnabled(bool value) => socket.readEventsEnabled = value;

  @override
  bool get writeEventsEnabled => socket.writeEventsEnabled;
  @override
  set writeEventsEnabled(bool value) => socket.writeEventsEnabled = value;

  @override
  int get multicastHops => socket.multicastHops;
  @override
  set multicastHops(int value) => socket.multicastHops = value;

  @override
  // ignore: deprecated_member_use
  NetworkInterface? get multicastInterface => socket.multicastInterface;
  @override
  set multicastInterface(NetworkInterface? value) =>
      // ignore: deprecated_member_use
      socket.multicastInterface = value;

  // Stream interface
  @override
  StreamSubscription<RawSocketEvent> listen(
    void Function(RawSocketEvent event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => socket.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  bool get isBroadcast => socket.isBroadcast;

  @override
  Stream<RawSocketEvent> asBroadcastStream({
    void Function(StreamSubscription<RawSocketEvent>)? onListen,
    void Function(StreamSubscription<RawSocketEvent>)? onCancel,
  }) => socket.asBroadcastStream(onListen: onListen, onCancel: onCancel);

  @override
  Stream<RawSocketEvent> where(bool Function(RawSocketEvent) test) =>
      socket.where(test);

  @override
  Stream<S> map<S>(S Function(RawSocketEvent) convert) => socket.map(convert);

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(RawSocketEvent) convert) =>
      socket.asyncMap(convert);

  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(RawSocketEvent) convert) =>
      socket.asyncExpand(convert);

  @override
  Stream<S> expand<S>(Iterable<S> Function(RawSocketEvent) convert) =>
      socket.expand(convert);

  @override
  Stream<RawSocketEvent> handleError(
    Function onError, {
    bool Function(dynamic)? test,
  }) => socket.handleError(onError, test: test);

  @override
  Stream<S> transform<S>(
    StreamTransformer<RawSocketEvent, S> streamTransformer,
  ) => socket.transform(streamTransformer);

  @override
  Future<RawSocketEvent> reduce(
    RawSocketEvent Function(RawSocketEvent, RawSocketEvent) combine,
  ) => socket.reduce(combine);

  @override
  Future<T> fold<T>(T initialValue, T Function(T, RawSocketEvent) combine) =>
      socket.fold(initialValue, combine);

  @override
  Future<String> join([String separator = '']) => socket.join(separator);

  @override
  Future<bool> any(bool Function(RawSocketEvent) test) => socket.any(test);

  @override
  Future<bool> every(bool Function(RawSocketEvent) test) => socket.every(test);

  @override
  Future<int> get length => socket.length;

  @override
  Future<bool> get isEmpty => socket.isEmpty;

  @override
  Future<List<RawSocketEvent>> toList() => socket.toList();

  @override
  Future<Set<RawSocketEvent>> toSet() => socket.toSet();

  @override
  Future<E> drain<E>([E? futureValue]) => socket.drain(futureValue);

  @override
  Stream<RawSocketEvent> take(int count) => socket.take(count);

  @override
  Stream<RawSocketEvent> takeWhile(bool Function(RawSocketEvent) test) =>
      socket.takeWhile(test);

  @override
  Stream<RawSocketEvent> skip(int count) => socket.skip(count);

  @override
  Stream<RawSocketEvent> skipWhile(bool Function(RawSocketEvent) test) =>
      socket.skipWhile(test);

  @override
  Stream<RawSocketEvent> distinct([
    bool Function(RawSocketEvent, RawSocketEvent)? equals,
  ]) => socket.distinct(equals);

  @override
  Future<RawSocketEvent> get first => socket.first;

  @override
  Future<RawSocketEvent> get last => socket.last;

  @override
  Future<RawSocketEvent> get single => socket.single;

  @override
  Future<RawSocketEvent> firstWhere(
    bool Function(RawSocketEvent) test, {
    RawSocketEvent Function()? orElse,
  }) => socket.firstWhere(test, orElse: orElse);

  @override
  Future<RawSocketEvent> lastWhere(
    bool Function(RawSocketEvent) test, {
    RawSocketEvent Function()? orElse,
  }) => socket.lastWhere(test, orElse: orElse);

  @override
  Future<RawSocketEvent> singleWhere(
    bool Function(RawSocketEvent) test, {
    RawSocketEvent Function()? orElse,
  }) => socket.singleWhere(test, orElse: orElse);

  @override
  Future<RawSocketEvent> elementAt(int index) => socket.elementAt(index);

  @override
  Stream<RawSocketEvent> timeout(
    Duration timeLimit, {
    void Function(EventSink<RawSocketEvent>)? onTimeout,
  }) => socket.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<bool> contains(Object? needle) => socket.contains(needle);

  @override
  Future<void> forEach(void Function(RawSocketEvent) action) =>
      socket.forEach(action);

  @override
  Stream<R> cast<R>() => socket.cast<R>();

  @override
  Future<void> pipe(StreamConsumer<RawSocketEvent> streamConsumer) =>
      socket.pipe(streamConsumer);
}
