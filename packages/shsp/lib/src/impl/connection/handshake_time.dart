import 'package:clock_dart/clock_dart.dart';
import '../../interfaces/connection/i_shsp_handshake.dart';

typedef InputHandshakeTime = ({
  int handshakeTimeframe, // how much from an handshake and the other
  int handshakeDuration, // how much last the handshake
  DateTime startHandshakeTime,
  DateTime endHandshakeTime,
});

typedef InputFactoryHandshakeTime = ({
  int? handshakeTimeframe,
  int? handshakeDuration,
  int? whenLastHandshake, // seconds from the start handshake to when there will be the last handshake
});

const InputFactoryHandshakeTime defaultHandshakeTimeInput = (
  handshakeTimeframe: 20,
  handshakeDuration: 10,
  whenLastHandshake: 6000,
);

class HandshakeTime implements IHandshakeTime {
  HandshakeTime(InputHandshakeTime input)
      : handshakeTimeframe = input.handshakeTimeframe,
        handshakeDuration = input.handshakeDuration,
        startHandshakeTime = input.startHandshakeTime,
        endHandshakeTime = input.endHandshakeTime;

  final int handshakeTimeframe;
  final int handshakeDuration;
  final DateTime startHandshakeTime;
  final DateTime endHandshakeTime;

  static Future<HandshakeTime> createAsync(
      InputFactoryHandshakeTime input) async {
    final clock = NTPClock();
    await clock.refresh();
    final now = clock.now();
    return HandshakeTime((
      handshakeTimeframe: input.handshakeTimeframe ??
          defaultHandshakeTimeInput.handshakeTimeframe!,
      handshakeDuration: input.handshakeDuration ??
          defaultHandshakeTimeInput.handshakeDuration!,
      startHandshakeTime: now,
      endHandshakeTime: now.add(Duration(
          seconds: input.whenLastHandshake ??
              defaultHandshakeTimeInput.whenLastHandshake!)),
    ));
  }

  @override
  int getHandshakeTimeframe() => handshakeTimeframe;
  int getHandshakeDuration() => handshakeDuration;
  @override
  DateTime getStartHandshakeTime() => startHandshakeTime;
  @override
  DateTime getEndHandshakeTime() => endHandshakeTime;
  @override
  int getSecondsToNextHandshake() => -1;
}
