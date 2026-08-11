# RFC-SHSP: Single HandShake Protocol

- **Status**: Draft
- **Version described**: implementation as of package `shsp` v1.11.1 (monorepo v1.11.0)
- **Category**: Informational / Protocol specification (transport session layer over UDP)

## Status of this document

This document describes SHSP as currently implemented in this repository. It is a **draft** meant to
serve as the canonical protocol reference; it is not a formal IETF submission, but follows RFC-style
structure and uses the key words **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT**, **MAY** as defined
in RFC 2119 to describe implementation requirements.

Several planned features (peer authentication, IP/NAT signaling, protocol version negotiation) exist
only as unused interfaces or dead code paths in the codebase. This document explicitly marks such
items as **not implemented** rather than describing them as active protocol behavior, and lists them
under [Section 11, Known Limitations and Future Work](#11-known-limitations-and-future-work).

## Table of contents

1. [Introduction](#1-introduction)
2. [Terminology](#2-terminology)
3. [Transport](#3-transport)
4. [Wire format](#4-wire-format)
5. [Connection states](#5-connection-states)
6. [Handshake procedure](#6-handshake-procedure)
7. [Keep-alive](#7-keep-alive)
8. [Connection termination](#8-connection-termination)
9. [Payload compression](#9-payload-compression)
10. [Error handling](#10-error-handling)
11. [Known limitations and future work](#11-known-limitations-and-future-work)
12. [Security considerations](#12-security-considerations)
13. [Versioning](#13-versioning)
14. [References](#14-references)

## 1. Introduction

SHSP (Single HandShake Protocol) is a lightweight session protocol layered directly on UDP. It gives
two endpoints ("peers") a connection-like abstraction — open / closing / closed — without the
multi-round-trip negotiation of protocols such as TCP's three-way handshake or TLS.

The name "single handshake" refers to the fact that a connection is considered established as soon as
each side has observed **one** handshake message from the other side; there is no multi-phase exchange
of capabilities, versions, or keys. A single message type, possibly repeated for reliability over lossy
UDP, is sufficient to open a session.

SHSP targets peer-to-peer scenarios across NATs, where the handshake message is also used to open
("punch") a NAT mapping so that return traffic from the peer is allowed back in. The protocol does not
implement any address-discovery (e.g. STUN) or relay (e.g. TURN) mechanism; it relies purely on
repeated outbound probes with backoff to increase the chance that both sides' NAT mappings are open at
the same time.

## 2. Terminology

- **Peer**: one endpoint of a session, identified by an `(InternetAddress, port)` pair.
- **Instance**: the local object representing a session with a specific remote peer (`ShspInstance`).
- **Socket**: the underlying UDP socket shared by one or more instances (`ShspSocket`).
- **Message**: a single UDP datagram, interpreted as one SHSP protocol unit.
- **Open**: state in which both peers have exchanged handshake acknowledgment and user data may flow.

## 3. Transport

- SHSP runs exclusively over **UDP** (`dart:io RawDatagramSocket`). It does not run over TCP,
  WebSocket, or any other transport in this implementation.
- Both **IPv4 and IPv6** are supported, including dual-stack operation where a peer maintains one
  socket per address family and routes outgoing messages by the destination address's family.
- SHSP relies on UDP's inherent datagram framing: **one `sendTo()` call corresponds to exactly one
  logical SHSP message**. There is no length prefix, delimiter, or reassembly logic at the SHSP layer.
- The maximum message size is **65,507 bytes**, the theoretical maximum UDP payload size. Messages
  larger than this, or empty messages, MUST be rejected by the sender.
- SHSP does not fragment or reassemble messages above the UDP datagram limit; that is the
  responsibility of the transport/OS/network path, with the usual risk of IP fragmentation for large
  datagrams.
- A socket MAY be replaced at runtime (e.g. on a network change) while preserving registered peer
  callbacks. This is a local resilience feature of the reference implementation and is not visible on
  the wire.

## 4. Wire format

Every SHSP message is a single UDP payload consisting of a 1-byte type prefix, optionally followed by
a body. There is no additional header (no sequence number, no length field, no checksum beyond what
UDP itself provides).

| Prefix (hex) | Name          | Body                                   | Direction / meaning                                   |
|--------------|---------------|-----------------------------------------|--------------------------------------------------------|
| `0x00`       | Data          | Application payload (optionally compressed) | User data, only valid once the connection is open |
| `0x01`       | Handshake     | none, or single byte `0x01` (ack form)  | Handshake probe (`[0x01]`) or acknowledgment (`[0x01, 0x01]`) |
| `0x02`       | Closing       | none                                     | Announce intent to close (soft close)                 |
| `0x03`       | Closed        | none                                     | Confirm final close                                    |
| `0x04`       | Keep-alive    | none                                     | Heartbeat while open                                    |

Notes:

- Control messages (handshake, closing, closed, keep-alive) are never compressed.
- Data messages MAY be compressed; when compression is enabled, everything after the `0x00` prefix
  byte is the compressed representation of the application payload (see [Section 9](#9-payload-compression)).
- Receipt of any prefix byte other than the five listed above MUST be treated as a protocol error.

## 5. Connection states

An instance tracks three independent boolean flags that together define its effective state:

- `handshakeState`: true once a handshake probe has been received from the peer.
- `openState`: true once both sides have confirmed the handshake (see [Section 6](#6-handshake-procedure)).
- `closingState`: true once a soft-close has been announced (locally or by the peer).

Effective states, in order of a typical lifecycle:

```
created -> handshaking -> open -> closing (optional) -> closed
```

- **created**: instance exists, no handshake sent or received yet.
- **handshaking**: at least one handshake probe has been sent and/or received, `openState` is false.
- **open**: `openState == true`. Data messages MAY be sent and received. Keep-alive is active.
- **closing**: `closingState == true`. The connection is still nominally usable, but a close is imminent.
- **closed**: the instance has sent or received a final close confirmation; it MUST NOT be reused.

## 6. Handshake procedure

The handshake is intentionally minimal and symmetric — both peers run identical logic.

1. Each side sends a handshake probe: `[0x01]`.
2. On receiving `[0x01]`, a peer sets `handshakeState = true` and MAY immediately reply with an
   acknowledgment: `[0x01, 0x01]`.
3. On receiving `[0x01, 0x01]` (a 2-byte handshake message whose second byte is `0x01`), a peer sets
   `openState = true`. A peer that has already set its own `handshakeState = true` and observes such an
   ack transitions to `open`.
4. Because UDP is unreliable, an instance SHOULD retransmit the handshake probe at a fixed interval
   until it observes `openState == true` or a timeout elapses. The reference implementation's default
   interval is 500 ms, with a default overall timeout of 5000 ms.
5. For NAT traversal scenarios, where a single fixed-interval attempt window may not be sufficient to
   align both peers' NAT mappings, an instance SHOULD instead use an exponential backoff retry
   strategy: default `maxAttempts = 10`, `initialDelayMs = 500`, `backoffMultiplier = 1.5` (total
   window ≈ 37 seconds). The retry loop stops as soon as the connection opens, or after the attempt
   budget is exhausted (in which case no exception is raised; the caller is notified via a
   max-attempts-exhausted callback).
6. There is no capability, version, or key negotiation during the handshake. A handshake message
   carries no information beyond "I am attempting to connect" / "I acknowledge your attempt".

Sequence diagram (happy path):

```
Peer A                              Peer B
  |--- [0x01] handshake ----------->|            (A: handshakeState local send)
  |                                 | handshakeState=true
  |<-- [0x01,0x01] ack -------------|
  | openState=true                  |
  |--- [0x01,0x01] ack ------------>|            (symmetric ack, if not already sent)
  |                                 | openState=true
  |=== both peers OPEN ============>|
```

In practice both sides send probes concurrently and the exact interleaving of probe/ack varies; the
protocol tolerates duplicate probes and acks arriving in either order.

## 7. Keep-alive

Once open, a peer SHOULD periodically send a keep-alive message (`[0x04]`) to signal liveness. The
reference implementation:

- sends a keep-alive only while the connection is open and not closing;
- resets its keep-alive timer whenever any outbound message (data or control) is sent, avoiding
  redundant traffic on active connections;
- treats keep-alive callback errors as non-fatal (logged, does not stop the timer).

Keep-alive interval default: 30 seconds. There is no protocol-defined liveness timeout on the
receiving side in the current implementation — the shipped protocol does not mark a peer as dead
after a period without keep-alive receipt; this is a candidate future improvement.

## 8. Connection termination

Two termination signals exist:

- **Closing** (`[0x02]`, soft): announces intent to close. Sets `closingState = true` locally and,
  when received, invokes an `onClosing` notification on the peer. It does not by itself tear down the
  instance or stop message flow.
- **Closed** (`[0x03]`, final): confirms termination. When received, resets `openState = false` and
  `closingState = false` and invokes an `onClose` notification. Sending `Closed` bypasses the normal
  "connection must be open/not-closing" send guard, since a peer must be able to announce closure even
  while in a closing or degraded state.

`close()` on an instance: if the connection was open, it sends `[0x03]`, then stops keep-alive and
performs local cleanup. Close is idempotent — a second call MUST NOT raise an error or resend
messages. Failure to send the final close message (e.g. because the underlying socket is already
gone) MUST be tolerated rather than propagated, since the local side is tearing down regardless.

## 9. Payload compression

Compression applies to data messages (`0x00` prefix) only; it is never applied to control messages.
When a compression codec is configured on a socket:

- On send: the payload after the `0x00` prefix is compressed with the configured codec before
  transmission.
- On receive: the payload after the `0x00` prefix is decompressed before being delivered to the
  application.

Supported codecs in the reference implementation: GZip (default), LZ4, Zstd, all implementing a common
`ICompressionCodec` interface. Compression is a purely local encoding choice between sender and
receiver configuration; it is not negotiated on the wire, so both peers MUST be configured with
compatible (or absent) compression settings out of band.

## 10. Error handling

The following error conditions are defined by the reference implementation and SHOULD be preserved by
any conforming implementation:

| Condition | Behavior |
|---|---|
| Unrecognized message type prefix | Protocol error raised to the application |
| Send attempted while not open | Send rejected: "connection is not open" |
| Send attempted while closing | Send rejected: "connection is closing" |
| Send attempted on a closed peer | Send rejected: "peer is closed" |
| Empty or oversized (> 65,507 bytes) message | Validation error, message not sent |
| Underlying socket reports 0 bytes written | Network error: "socket buffer may be full" |
| Bind to an invalid port | Validation error: "port must be between 0 and 65535" |
| Handshake timeout reached without opening | No exception; caller must check open state |
| Handshake retries exhausted | No exception; a callback is invoked |
| Double close / already-closed instance | No-op (idempotent) |
| Dual-stack send with no socket for the address family | State error naming the missing family |

There is **no on-the-wire protocol version field and no version negotiation**. Compatibility between
peers running different implementation versions is not automatically detected or enforced; this is a
known gap (see [Section 11](#11-known-limitations-and-future-work)).

## 11. Known limitations and future work

The codebase contains interfaces and data types that describe intended future protocol extensions;
none of the following are active on the wire today, and this document does not describe them as
current behavior:

- **Peer authentication / nonce signing**: an `IHandshakeOwnership` interface describes signing a nonce
  with a private key, verifiable by the peer's public key, to mitigate handshake spoofing. The concrete
  implementation currently just echoes a pre-supplied string; no actual cryptographic signing or
  verification takes place.
- **NAT/IP signaling** (`HandshakeSignal`, `SecuritySignal`): data classes designed to exchange
  public/local IPv4/IPv6 addresses, a public key, and handshake timing windows between peers, are
  defined but never sent by the current handshake logic.
- **STUN-based address discovery**: previously present, removed in v1.11.0. No replacement address
  discovery or relay/TURN fallback exists; symmetric-NAT peers cannot establish a connection with the
  current design.
- **Protocol version negotiation**: no version byte or negotiation step exists; version compatibility
  is managed only via out-of-band package versioning (semver), not on the wire.
- **Peer liveness timeout**: keep-alive is sent, but there is no built-in expiry of a peer considered
  unresponsive after missed keep-alives.

These items are natural candidates for a future protocol revision (e.g. "SHSP v2") rather than gaps in
the current implementation of "v1".

## 12. Security considerations

The protocol as implemented provides **no confidentiality, integrity, or authentication guarantees**:

- Any host that can send UDP packets to an open port can send handshake, data, or close messages;
  there is no verification that a peer is who it claims to be.
- Data payloads are sent in the clear (compression is not encryption).
- Because closing (`[0x03]`) is accepted from any source address matching the registered peer tuple,
  and there is no authentication, a third party capable of spoofing that address/port (as is possible
  on unauthenticated UDP paths) could disrupt a session.
- Applications requiring confidentiality, integrity, or peer authentication MUST implement these at a
  layer above SHSP (e.g. encrypting the data payload before calling `sendMessage`) until a protocol
  revision implements the aspirational signing scheme described in [Section 11](#11-known-limitations-and-future-work).

## 13. Versioning

- This document describes the protocol as implemented by package `shsp` v1.11.1 (monorepo v1.11.0).
- The protocol itself carries no version identifier on the wire; "protocol version" in this document
  refers to the behavior shipped in the referenced package version.
- Changes to wire-visible behavior (message prefixes, handshake semantics, state transitions) SHOULD be
  reflected in this document, with a revision note added below.

### Revision history

| Version of this doc | Date | Notes |
|---|---|---|
| 0.1 (draft) | 2026-08-09 | Initial draft, derived from `shsp` v1.11.1 implementation |

## 14. References

- `packages/shsp/lib/src/impl/instance/core/shsp_instance.dart` — message dispatch, prefixes, data send path
- `packages/shsp/lib/src/impl/instance/features/shsp_instance_handshake.dart` — handshake logic
- `packages/shsp/lib/src/impl/instance/handlers/shsp_handshake_handler.dart` — fixed-interval handshake loop
- `packages/shsp/lib/src/impl/instance/handlers/shsp_handshake_retry_handler.dart` — exponential backoff retry
- `packages/shsp/lib/src/impl/mixins/message_size_validation_mixin.dart` — size limits
- `packages/shsp/lib/src/impl/socket/features/shsp_socket_compression.dart` — compression
- `packages/shsp/lib/src/interfaces/connection/i_shsp_handshake.dart` — unimplemented signing/signal interfaces
- `SHSP_HANDSHAKE_RETRY_HANDLER.md` — detailed retry/backoff reference
- `packages/shsp/CHANGELOG.md` — protocol/API history, including STUN removal in v1.11.0
