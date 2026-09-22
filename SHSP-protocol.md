# RFC-SHSP: Single HandShake Protocol

- **Status**: Draft
- **Category**: Standards Track (transport session layer over UDP)

## Status of this document

This document specifies SHSP, a minimal session-establishment protocol layered over UDP. It follows
RFC-style structure and uses the key words **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT**, **MAY**
as defined in RFC 2119. The specification is protocol-first: it defines wire format, state machine,
and required behavior independently of any particular implementation. Numeric defaults given in this
document (timer values, retry counts) are RECOMMENDED starting points, not fixed protocol constants;
a conforming implementation MAY expose them as configuration as long as both endpoints of a session
remain interoperable at the wire level.

Peer authentication, address/NAT signaling, address-discovery/relay, and payload compression are
explicit non-goals of this specification, delegated to any protocol or application layered above SHSP
(see [Section 11.1](#111-explicit-non-goals) and [Section 9](#9-payload-compression)). Protocol version
compatibility is likewise not negotiated on the wire by design (see
[Section 11.2](#112-version-compatibility-is-not-negotiated-by-design)). [Section 13](#13-conformance)
states the minimal set of mandatory, interoperability-critical requirements — including the pinned
value `VERSION = 0x00` for this revision — that make two independent implementations of this document
interoperable.

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
    - 11.1 [Explicit non-goals](#111-explicit-non-goals)
    - 11.2 [Version compatibility is not negotiated, by design](#112-version-compatibility-is-not-negotiated-by-design)
    - 11.3 [Peer liveness timeout](#113-peer-liveness-timeout)
12. [Security considerations](#12-security-considerations)
13. [Conformance](#13-conformance)
14. [Versioning](#14-versioning)
15. [References](#15-references)

## 1. Introduction

SHSP (Single HandShake Protocol) is a lightweight session protocol layered directly on UDP. It gives
two endpoints ("peers") a connection-like abstraction — open / closing / closed — without the
multi-round-trip negotiation of protocols such as TCP's three-way handshake or TLS.

The name "single handshake" refers to the fact that a session is considered established as soon as
each side has observed **one** handshake message from the other side; there is no multi-phase exchange
of capabilities or keys, and no negotiation of versions. A single message type, possibly repeated for
reliability over lossy UDP, is sufficient to open a session.

SHSP targets peer-to-peer scenarios across NATs, where the handshake message doubles as a NAT-punching
probe: sending it opens an outbound mapping so that return traffic from the peer is permitted back in.
The protocol does not itself define an address-discovery (e.g. STUN-like) or relay (e.g. TURN-like)
mechanism; endpoints are expected to already possess a candidate address for their peer, and SHSP
relies on repeated probes with backoff to raise the probability that both sides' mappings are open
concurrently.

## 2. Terminology

- **Peer**: one endpoint of a session, identified by a (network address, port) pair.
- **Session**: a bidirectional logical connection between two peers, tracked independently by each
  side as a local state machine.
- **Endpoint**: an implementation of this protocol, capable of hosting one or more concurrent sessions
  over a shared or per-session UDP socket.
- **Message**: a single UDP datagram, interpreted in its entirety as one SHSP protocol unit.
- **Open**: the state in which both peers have confirmed the handshake and application data may flow.

## 3. Transport

- SHSP runs exclusively over **UDP**. It is not defined over TCP, WebSocket, or any other transport.
- SHSP is address-family agnostic: both **IPv4 and IPv6** are supported. An endpoint operating in
  dual-stack mode routes each outgoing message according to the destination address's family.
- SHSP relies on UDP's inherent datagram framing: **one transmitted datagram corresponds to exactly
  one logical SHSP message**. The protocol defines no length prefix, delimiter, or reassembly logic of
  its own.
- The maximum message size is bounded by the maximum UDP payload size (65,507 bytes for IPv4/IPv6
  unicast). A conforming sender MUST reject messages larger than this limit, and MUST reject empty
  messages.
- SHSP does not fragment or reassemble messages exceeding the UDP datagram limit; that responsibility
  belongs to lower layers, with the attendant risk of IP-level fragmentation for large datagrams.
- Underlying transport resources (e.g. sockets) MAY be replaced at runtime without being visible on
  the wire; such continuity is a local implementation concern, not a protocol property.

## 4. Wire format

Every SHSP message is a single UDP payload consisting of a 1-byte type prefix, optionally followed by
a body. No additional header is defined (no sequence number, no length field, no checksum beyond what
UDP itself provides).

| Prefix (hex) | Name           | Body | Direction / meaning                                           |
|--------------|----------------|------|-----------------------------------------------------------------|
| `0x00`       | Data           | Application payload (opaque bytes) | User data; valid only once the session is open |
| `0x01`       | Handshake      | 1 byte, mandatory: protocol version (`0x00` = version 0, `0x01` = version 1, ...) | Handshake probe |
| `0x02`       | Handshake-Ack  | none | Handshake acknowledgment (confirms the session as open) |
| `0x03`       | Closing        | none | Announce intent to close (soft close)                           |
| `0x04`       | Closed         | none | Confirm final close                                              |
| `0x05`       | Keep-alive     | none | Heartbeat while open                                             |

Notes:

- The body of a Data message is opaque to SHSP: whatever bytes the application hands to SHSP for
  sending are the bytes delivered to the receiving application, unmodified. SHSP does not compress,
  encrypt, or otherwise transform this payload (see [Section 9](#9-payload-compression)).
- Receipt of any prefix byte other than the six listed above MUST be treated as a protocol error.
- The `VERSION` byte in a Handshake message is mandatory. A Handshake message received without it
  (i.e. a 1-byte datagram containing only the `0x01` prefix) MUST be treated as malformed; it MUST NOT
  be interpreted as an implicit version `0x00`.

## 5. Connection states

Each side of a session maintains an independent state machine with the following states:

```
CREATED -> HANDSHAKING -> OPEN -> CLOSING (optional) -> CLOSED
```

- **CREATED**: session exists; no handshake message sent or received yet. A peer exits CREATED as soon
  as it either sends its own handshake probe (Section 6, step 1) or receives one from its counterpart —
  both events move it into HANDSHAKING (see the definition below). Because a conforming peer only sends
  a non-handshake message (Data, Keep-alive, Closing, Closed) after observing a probe from its
  counterpart (see [Section 6](#6-handshake-procedure)), and because sending its own probe already exits
  CREATED, no message other than a Handshake probe (`0x01`) can legitimately be received while still in
  this state. A message with any other prefix received while in CREATED MUST be discarded.
- **HANDSHAKING**: at least one handshake probe has been sent and/or a probe has been received from
  the peer, but the session is not yet open.
- **OPEN**: the handshake has been confirmed by receipt of an acknowledgment (see
  [Section 6](#6-handshake-procedure)). Data messages MAY be sent and received; keep-alive is active.
- **CLOSING**: a soft-close has been announced, locally or by the peer. A peer in CLOSING MUST NOT send
  further Data or Keep-alive messages, but MUST continue to receive and process incoming messages from
  the peer (including a subsequent `Closed`). Termination is imminent.
- **CLOSED**: a final close has been sent or received. No further messages MAY be sent, and no further
  incoming messages for this session MAY be processed; a session MUST NOT be reused once CLOSED. An
  implementation MUST release the resources associated with the session at this point (e.g. closing an
  owned socket, discarding registered callbacks) rather than continuing to process datagrams for it.

The state machine is driven purely by locally observed events (messages sent or received); there is no
shared or negotiated state between peers beyond what these messages convey.

## 6. Handshake procedure

The handshake is intentionally minimal and symmetric: both peers execute identical logic, and there is
no distinguished initiator or responder role at the protocol level.

1. **Each side independently** sends its own handshake probe carrying its own protocol version:
   `[0x01, VERSION]`. Sending this probe is unconditional — it is not sent in reply to anything, but as
   part of initiating the session on that side. Both peers do this concurrently; neither waits for the
   other's probe before sending its own. Implementations conforming to **this revision** of the
   specification MUST send `VERSION = 0x00` (see [Section 13](#13-conformance)).
2. On receiving `[0x01, VERSION]`, a peer records that a probe has been observed from its counterpart,
   together with the counterpart's declared version, and MUST reply with a handshake acknowledgment:
   `[0x02]`, and SHOULD do so immediately. The acknowledgment carries no body — the version is declared
   only once, by the peer that sent the original probe. A peer that never acknowledges a received probe
   prevents its counterpart from ever reaching OPEN.
3. On receiving `[0x02]` (a handshake acknowledgment), a peer transitions to OPEN. Because both sides
   send their own probe independently (step 1), each side's probe triggers an ack from the other,
   allowing both sides to reach OPEN without depending on each other's ack for anything but their own
   transition.
4. Because UDP is unreliable, a peer SHOULD retransmit its handshake probe at a bounded interval until
   it reaches OPEN or a timeout elapses. Silence past the timeout MUST NOT raise a protocol error; it
   is a normal outcome that the caller is expected to observe by checking session state.
5. For NAT-traversal scenarios, where a single fixed-interval attempt window may not suffice to align
   both peers' NAT mappings, a peer SHOULD instead use an exponential-backoff retry strategy, bounded
   by a maximum attempt count. Exhausting the attempt budget without reaching OPEN MUST be reported to
   the caller as a distinct, non-exceptional outcome (e.g. via a callback or status value), not as an
   error.
6. The `VERSION` byte carried in the probe is a **declarative** identifier of the sender's protocol
   version; it is not negotiated, and the acknowledgment does not repeat or echo it. Receipt of a
   `VERSION` value different from the local peer's own does not by itself block, alter, or downgrade
   the handshake — an implementation MAY use it for logging, diagnostics, or an out-of-band
   compatibility policy, but MUST NOT derive security-relevant behavior from it (see
   [Section 12](#12-security-considerations)). Beyond this version byte, the handshake carries no
   capability or key negotiation.
7. **Implicit confirmation.** Because a conforming peer only sends Data (`0x00`) or Keep-alive (`0x05`)
   while its own session is OPEN (Section 7, Section 10), receiving either of these while still in
   HANDSHAKING (i.e. before having received `[0x02]` for one's own probe) is proof that the counterpart
   has already reached OPEN, which in turn is only possible if the local peer's earlier acknowledgment
   reached it. A peer that receives `0x00` or `0x05` while in HANDSHAKING SHOULD treat this as an
   implicit handshake confirmation, equivalent to receiving `[0x02]`, and transition to OPEN. This
   compensates for the case where the local peer's own `[0x02]` acknowledgment to the counterpart was
   lost, while the counterpart's subsequent traffic was not.
8. Conversely, a peer that receives `[0x03]` (Closing) or `[0x04]` (Closed) while still in HANDSHAKING
   MUST NOT transition to OPEN as a result; the session remains unopened and is handled per
   [Section 8](#8-connection-termination) instead.
9. Once a peer has reached OPEN, it SHOULD stop sending `[0x02]` in response to further (duplicate)
   handshake probes from the same counterpart. This is safe because, per point 7 above, the peer's
   regular OPEN traffic (Data, and in particular the periodic Keep-alive of
   [Section 7](#7-keep-alive)) already gives the counterpart everything it needs to detect that the
   handshake succeeded, even if a specific `[0x02]` was lost. An implementation MAY still choose to keep
   acknowledging duplicate probes; both behaviors are conforming.

Sequence diagram (happy path — both peers send their own probe independently, per step 1):

```
Peer A                              Peer B
  |--- [0x01, VERSION] handshake -->|
  |<-- [0x01, VERSION] handshake ---|            (B's own probe, sent independently)
  |                                 |
  | (A's probe observed by B)       | (B's probe observed by A)
  |<-- [0x02] ack -------------------|            (B acks A's probe)
  |--- [0x02] ack ------------------->|            (A acks B's probe)
  |                                 |
  | (transitions to OPEN)           | (transitions to OPEN)
  |=== both peers OPEN ==============|
```

In practice both sides may send probes concurrently, and the exact interleaving of probes and
acknowledgments varies. A conforming implementation MUST tolerate duplicate probes and acknowledgments
arriving in any order or multiplicity.

## 7. Keep-alive

Once a session is OPEN, a peer SHOULD periodically send a keep-alive message (`[0x05]`) to signal
liveness to its counterpart. A conforming implementation:

- sends keep-alive only while the session is open and not closing;
- SHOULD suppress a scheduled keep-alive if other outbound traffic (data or control) has already been
  sent recently, to avoid redundant signaling on active sessions;
- MUST treat failures in local keep-alive processing as non-fatal to the session.

An endpoint MAY be configured with a **liveness timeout**: a duration after which, if no message of
any kind (data, control, or keep-alive) has been received from the peer, the session is considered
unresponsive. On expiry of this timeout:

- the endpoint SHOULD close the session locally, following the same procedure as a local `close()`
  (Section 8), without waiting for or requiring any message from the peer;
- the timeout MUST be reset on receipt of **any** message from the peer, not only keep-alive messages;
- this is a purely local, unilateral decision — the peer is not notified that it was deemed
  unresponsive except via the normal `Closed` message sent as part of local teardown, which it MAY
  never receive if it truly is unreachable.

The liveness timeout is OPTIONAL and its duration is a local configuration choice; this specification
does not mandate a default. An endpoint with no liveness timeout configured relies solely on the
application to decide when a session is stale.

As a RECOMMENDED starting point (a local configuration default, not a protocol constant — see "Status
of this document"), a liveness timeout of **60 seconds** paired with a keep-alive interval of **15
seconds** gives the peer three to four opportunities to be heard from before the session is declared
unresponsive, tolerating the occasional lost datagram without prematurely closing a healthy session. An
implementation MAY scale the keep-alive interval to roughly a quarter to a third of the configured
liveness timeout to preserve this margin if the timeout is changed.

## 8. Connection termination

Two termination signals exist:

- **Closing** (`[0x03]`, soft): announces intent to close. Sets the local state to CLOSING. Once in
  CLOSING, a peer MUST NOT send further Data or Keep-alive messages, but MUST continue to receive and
  process incoming messages from the peer. Upon receipt, a peer SHOULD surface a "closing" notification
  to the receiving application.
- **Closed** (`[0x04]`, final): confirms termination. Upon receipt, a peer MUST clear its OPEN and
  CLOSING state, transition to CLOSED, and SHOULD surface a "closed" notification to the application. A
  `Closed` message MAY be sent regardless of current session state — a peer MUST be able to announce
  closure even while already in a closing or otherwise degraded state.

Closing a session that is OPEN SHOULD first send `[0x03]` to announce intent and transition to CLOSING,
then send `[0x04]` before releasing local resources associated with the session. Once `[0x04]` has been
sent or received, the session is CLOSED: a peer MUST NOT send or process any further message for this
session, and MUST release its associated resources (e.g. close an owned socket, discard registered
callbacks). Closure MUST be idempotent: a repeated close request on an already-closed session MUST NOT
raise an error or cause any message to be retransmitted. Failure to transmit the final close message
(e.g. because the underlying transport is already unavailable) MUST be tolerated rather than propagated
as an error, since the local side proceeds with teardown regardless.

## 9. Payload compression

**Compression is not part of SHSP.** SHSP defines no compression mechanism, codec, or encoding
convention for the Data message body; the body is opaque application payload, transmitted and
delivered byte-for-byte (Section 4). SHSP MUST NOT interpret, transform, or assume any particular
encoding of this payload.

If an application wants its data compressed on the wire, it MUST compress the payload itself before
handing it to SHSP for sending, and decompress it itself after receiving it from SHSP — from SHSP's
point of view, the compressed bytes are simply the Data message body, indistinguishable from
uncompressed application data. Codec choice, and any agreement between the two ends of a session on
which codec (if any) is in use, is entirely an application-layer concern, out of scope of this
specification.

## 10. Error handling

The following error conditions are defined by this specification and SHOULD be preserved by any
conforming implementation:

| Condition | Behavior |
|---|---|
| Unrecognized message type prefix | Protocol error raised to the application |
| Send attempted while not open | Send rejected: session not open |
| Send attempted while closing | Send rejected: session is closing |
| Send attempted on a closed session | Send rejected: session is closed |
| Message received for a session already CLOSED | Discarded; the session's resources (e.g. socket, callbacks) have already been released and no further processing occurs |
| Empty or oversized (> 65,507 bytes) message | Validation error, message not sent |
| Transport reports zero bytes written | Network error: outbound buffer may be full |
| Bind to an invalid port | Validation error: port out of range |
| Handshake timeout reached without opening | No exception; caller must check session state |
| Handshake retries exhausted | No exception; a distinct outcome is reported |
| Double close / already-closed session | No-op (idempotent) |
| Send with no local transport bound for the destination's address family | State error naming the missing family |
| Handshake message missing the mandatory `VERSION` byte (1-byte datagram) | Protocol error: malformed handshake, message discarded |
| Data (`0x00`) or Keep-alive (`0x05`) received while in HANDSHAKING | Treated as implicit handshake confirmation; peer transitions to OPEN (Section 6, point 7) |
| Closing (`0x03`) or Closed (`0x04`) received while in HANDSHAKING | Session does not transition to OPEN; handled per Section 8 |
| Any message with a prefix other than Handshake (`0x01`) received while in CREATED | Message discarded (cannot legitimately originate from a conforming peer) |

The handshake carries a `VERSION` byte (Section 6), but it is **declarative only — there is no
on-the-wire version negotiation, by design**. Compatibility between peers implementing different
versions is not detected or enforced by the protocol; a mismatch is, at most, observable by the
receiving application. Whether a given pair of versions can interoperate at all is a property of those
versions, not a protocol-level guarantee (see
[Section 11.2](#112-version-compatibility-is-not-negotiated-by-design)).

## 11. Known limitations and future work

### 11.1 Explicit non-goals

The following capabilities are **intentionally out of scope** of SHSP. They are not gaps to be closed
by a future revision of this protocol; responsibility for them belongs to any protocol layered above
SHSP, which is expected to run its own handshake/exchange once the SHSP session is open:

- **Peer authentication / nonce signing**: verifying that a peer is who it claims to be (e.g. by
  signing a nonce with a private key, verifiable via a public key) is not a concern of SHSP. SHSP MUST
  NOT be extended with such a mechanism; it belongs to a higher-layer protocol.
- **NAT/address signaling**: exchanging public/local IPv4/IPv6 addresses, keys, or timing windows
  between peers is not a concern of SHSP beyond the incidental NAT-punching side effect of the
  handshake probe itself (Section 1). Any explicit signaling of this kind is the responsibility of a
  higher-layer protocol.
- **Address-discovery (STUN-like) and relay (TURN-like) mechanisms**: SHSP does not provide, and will
  not provide, address discovery or relay/fallback for peers that cannot establish a direct UDP path
  (e.g. behind symmetric NATs). This is left entirely to whatever layer supplies SHSP with a
  destination address.

### 11.2 Version compatibility is not negotiated, by design

Version compatibility in SHSP is a property of the specific pair of versions involved, not a
protocol-mediated outcome. There is deliberately **no negotiation**: a session either opens — because
the two implementations involved are wire-compatible enough to complete the handshake and exchange
data — or it does not. Some version pairs will be compatible with each other, others will not;
`VERSION` (Section 6) lets a peer observe which is the case, but SHSP does not attempt to detect,
report, or resolve a mismatch itself. This is a deliberate design choice, not an omission to be fixed.

### 11.3 Peer liveness timeout

Addressed: Section 7 specifies an optional, locally-configured liveness timeout that closes a session
after a period without any received message.

## 12. Security considerations

The protocol as specified provides **no confidentiality, integrity, or authentication guarantees**:

- Any host able to send UDP packets to a listening endpoint can send handshake, data, or close
  messages; the protocol provides no mechanism to verify that a peer is who it claims to be.
- Data payloads are sent in the clear; compression is not encryption and provides no confidentiality.
- Because a `Closed` message is accepted from any source address matching the session's peer tuple,
  and no authentication is defined, a third party capable of spoofing that address/port — feasible on
  unauthenticated UDP paths — could disrupt a session.
- The `VERSION` byte carried in the handshake probe (Section 6) is sent in the clear and is trivially
  observable or forgeable by an on-path or spoofing attacker. This is an acceptable exposure only
  because the byte is purely declarative: no security-relevant decision, negotiation, or downgrade path
  MAY be driven by its value, at the SHSP layer or by any independent protocol layered above it. An
  implementation MUST NOT treat the `VERSION` byte as authoritative input for selecting cryptographic
  parameters or other security behavior.
- Because no authentication is defined, a third party able to spoof the peer's source address/port can
  send arbitrary messages (including keep-alive) that reset an endpoint's liveness timeout (Section 7).
  This lets an attacker keep a session with an actually-unresponsive or hijacked peer artificially
  alive, defeating local liveness-based cleanup. Applications relying on the liveness timeout for
  resource reclamation SHOULD NOT treat it as a security control.
- Applications requiring confidentiality, integrity, or peer authentication MUST implement these at a
  layer above SHSP (e.g. by encrypting the data payload before it is handed to SHSP for transmission,
  and running their own authenticated handshake once the SHSP session is open). This is a permanent
  property of SHSP, not a gap awaiting a future revision (see
  [Section 11.1](#111-explicit-non-goals)).

## 13. Conformance

This section states, in one place, what an implementation MUST do to be a conformant implementation of
**this revision** of SHSP.

**Mandatory (interoperability-critical) — a conformant implementation MUST:**

- Use the six message prefixes exactly as defined in [Section 4](#4-wire-format) (`0x00`–`0x05`), and
  treat any other prefix as a protocol error.
- Send `VERSION = 0x00` in every handshake probe ([Section 6](#6-handshake-procedure), step 1), and
  reject/treat as malformed a handshake probe with no `VERSION` byte.
- Implement the state machine of [Section 5](#5-connection-states) (CREATED → HANDSHAKING → OPEN →
  CLOSING → CLOSED) with the transition triggers defined in Sections 6 and 8.
- Reject empty messages and messages larger than 65,507 bytes ([Section 3](#3-transport)).
- Treat the Data message body as opaque application bytes, applying no transformation of its own
  ([Section 9](#9-payload-compression)).
- Tolerate duplicate or out-of-order handshake probes and acknowledgments ([Section 6](#6-handshake-procedure)).
- Handle `Closing` and `Closed` as defined in [Section 8](#8-connection-termination): accept `Closed`
  regardless of current session state, treat closure as idempotent (no error, no retransmission on a
  repeated close of an already-closed session), stop sending Data/Keep-alive once locally CLOSING, and
  stop sending or processing any message and release associated resources once CLOSED.

Two independent conformant implementations that both satisfy the mandatory list above are guaranteed
to be able to open a session and exchange Data messages with each other.

**Local/configurable (not interoperability-critical) — a conformant implementation MAY vary:**

- Handshake retransmission interval and strategy (fixed-interval or exponential backoff), and their
  timeout/attempt-budget values ([Section 6](#6-handshake-procedure)).
- Whether and how often keep-alive is sent, and whether a liveness timeout is configured, together with
  its duration ([Section 7](#7-keep-alive)).
- Whether the application layer built on top of SHSP applies compression, encryption, or any other
  transformation to the Data payload before/after handing it to SHSP ([Section 9](#9-payload-compression)) —
  this is invisible to SHSP and does not affect conformance.

None of the items in this second list need to match between the two peers of a session for the session
to interoperate at the SHSP level.

## 14. Versioning

- This document specifies the wire format, state machine, and required behavior of SHSP independently
  of any single implementation's release cadence.
- The handshake carries a declarative `VERSION` byte (Section 6). Implementations of this revision of
  the specification MUST use `VERSION = 0x00` (Section 13); this value identifies the revision, but is
  not used for on-the-wire negotiation and is not authoritative for interoperability decisions
  (Section 11.2) — a receiving peer observing a different `VERSION` value knows it is talking to a
  different revision, but SHSP itself does not decide what to do about it.
- A future revision of this specification that changes wire-visible, interoperability-critical
  behavior (the mandatory list in Section 13) MUST increment `VERSION`. A revision that only clarifies
  wording or adjusts locally-configurable defaults MAY keep `VERSION` unchanged.
- Changes to wire-visible behavior (message prefixes, handshake semantics, state transitions) SHOULD be
  reflected in this document, with a revision note added below.


## 15. References

This document is protocol-first and does not bind its normative text to any single implementation's
source layout. Implementers seeking a concrete reference for the behavior described above should
consult the accompanying implementation's handshake, state-machine, and message-dispatch modules, and
its changelog for the history of removed or superseded mechanisms (e.g. address-discovery support
present in earlier revisions and removed as this specification's scope was narrowed).
