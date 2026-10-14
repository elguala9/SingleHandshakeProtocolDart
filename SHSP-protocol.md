# RFC-SHSP: Single HandShake Protocol

- **Status**: Draft
- **Category**: Standards Track (transport session layer over UDP)

## Status of this document

This document specifies SHSP, a minimal session-establishment protocol layered over UDP. It follows
RFC-style structure and uses the key words **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT**, **MAY**
as defined in BCP 14 [RFC 2119] [RFC 8174] when, and only when, they appear in all capitals. The
specification is protocol-first: it defines wire format, state machine, and required behavior
independently of any particular implementation. Numeric defaults given in this document (timer values,
retry counts, size limits) are RECOMMENDED starting points, not fixed protocol constants; a conforming
implementation MAY expose them as configuration as long as both endpoints of a session remain
interoperable at the wire level.

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
7. [Keep-alive and liveness](#7-keep-alive-and-liveness)
8. [Connection termination](#8-connection-termination)
9. [Payload compression](#9-payload-compression)
10. [Error handling](#10-error-handling)
11. [Known limitations](#11-known-limitations)
    - 11.1 [Explicit non-goals](#111-explicit-non-goals)
    - 11.2 [Version compatibility is not negotiated, by design](#112-version-compatibility-is-not-negotiated-by-design)
    - 11.3 [No session identifier on the wire](#113-no-session-identifier-on-the-wire)
12. [Security considerations](#12-security-considerations)
13. [Conformance](#13-conformance)
14. [Versioning](#14-versioning)
15. [References](#15-references)

## 1. Introduction

SHSP (Single HandShake Protocol) is a lightweight session protocol layered directly on UDP. It gives
two endpoints ("peers") a connection-like abstraction — open / closing / closed — without the
multi-round-trip negotiation of protocols such as TCP's three-way handshake or TLS.

The name "single handshake" refers to the fact that a session is considered established as soon as
each side has observed an acknowledgment of **one** handshake message it sent; there is no multi-phase
exchange of capabilities or keys, and no negotiation of versions. A single message type, repeated for
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
- **Application payload**: the bytes carried in the body of a Data message.
- **Open**: the state in which the local peer has confirmed the handshake and application data may flow.

## 3. Transport

- SHSP runs exclusively over **UDP** [RFC 768]. It is not defined over TCP, WebSocket, or any other
  transport.
- SHSP is address-family agnostic: both **IPv4 and IPv6** are supported. An endpoint operating in
  dual-stack mode routes each outgoing message according to the destination address's family.
- SHSP relies on UDP's inherent datagram framing: **one transmitted datagram corresponds to exactly
  one logical SHSP message**. The protocol defines no length prefix, delimiter, or reassembly logic of
  its own.
- A message is never empty: it always contains at least the 1-byte type prefix. A received datagram of
  zero bytes MUST be discarded.
- The maximum message size is bounded by the maximum UDP payload size: **65,507 bytes over IPv4** and
  **65,527 bytes over IPv6** (jumbograms excluded). Since the type prefix occupies one byte, the maximum
  application payload of a Data message is one byte less (65,506 / 65,526 bytes). A conforming sender
  MUST reject a Data send whose application payload is empty or exceeds the limit for the destination's
  address family.
- SHSP does not fragment or reassemble messages; large datagrams rely on IP-level fragmentation, which
  is frequently dropped by NATs and firewalls. Senders SHOULD keep messages at or below **1,200 bytes**
  unless the path is known to support larger datagrams; segmentation of larger application data is an
  application-layer concern.
- Underlying transport resources (e.g. sockets) MAY be replaced at runtime without being visible on
  the wire; such continuity is a local implementation concern, not a protocol property.

## 4. Wire format

Every SHSP message is a single UDP payload consisting of a 1-byte type prefix, optionally followed by
a body. No additional header is defined (no sequence number, no length field, no session identifier,
no checksum beyond what UDP itself provides).

| Prefix (hex) | Name           | Body | Meaning                                                       |
|--------------|----------------|------|---------------------------------------------------------------|
| `0x00`       | Data           | Application payload (opaque bytes, at least 1 byte) | User data; valid only once the session is open |
| `0x01`       | Handshake      | 1 byte, mandatory: protocol version (`0x00` for this revision) | Handshake probe |
| `0x02`       | Handshake-Ack  | none | Acknowledges a received handshake probe                       |
| `0x03`       | Closing        | none | Requests a graceful close                                     |
| `0x04`       | Closed         | none | Final close (confirmation of `Closing`, or abortive close)    |
| `0x05`       | Keep-alive     | none | Heartbeat while open                                          |

Notes:

- The body of a Data message is opaque to SHSP: whatever bytes the application hands to SHSP for
  sending are the bytes delivered to the receiving application, unmodified. SHSP does not compress,
  encrypt, or otherwise transform this payload (see [Section 9](#9-payload-compression)).
- A message whose prefix byte is not one of the six listed above MUST be discarded without affecting
  session state. An implementation MAY log it or count it for diagnostics; it MUST NOT close the
  session because of it.
- The `VERSION` byte in a Handshake message is mandatory. A Handshake message received without it
  (i.e. a 1-byte datagram containing only the `0x01` prefix) is malformed and MUST be discarded; it
  MUST NOT be interpreted as an implicit version `0x00`.
- **Extensibility**: a receiver MUST ignore any bytes following the `VERSION` byte of a Handshake
  message, and any body attached to a Handshake-Ack, Closing, Closed, or Keep-alive message, and MUST
  process the message as if those bytes were absent. Senders conforming to this revision MUST NOT add
  such bytes. This reserves room for future revisions without breaking existing receivers.

## 5. Connection states

Each side of a session maintains an independent state machine with the following states:

```
CREATED ──► HANDSHAKING ──► OPEN ──► CLOSING ──► CLOSED
               │              │                    ▲
               └──────────────┴────────────────────┘
                   (Closed sent/received, Closing received,
                    handshake failure, liveness timeout)
```

- **CREATED**: session exists; no handshake message sent or received yet. A peer exits CREATED as soon
  as it either sends its own handshake probe (Section 6, step 1) or receives one from its counterpart —
  both events move it into HANDSHAKING. A message with any prefix other than Handshake (`0x01`)
  received while in CREATED MUST be discarded.
- **HANDSHAKING**: at least one handshake probe has been sent and/or a probe has been received from
  the peer, but the session is not yet open. Exits to OPEN (Section 6), or to CLOSED on handshake
  failure or on a termination signal (Section 8).
- **OPEN**: the handshake has been confirmed (Section 6, steps 3 and 6). Data messages MAY be sent and
  received; keep-alive is active.
- **CLOSING**: the local peer has requested a graceful close by sending `Closing` and is waiting for
  the peer's `Closed`. A peer in CLOSING MUST NOT send Data or Keep-alive messages, but MUST continue
  to receive and process incoming messages, including delivering received Data to the application.
  CLOSING is bounded by a closing timeout (Section 8).
- **CLOSED**: terminal. No further messages MAY be sent, and incoming messages for this session MUST
  NOT be processed; a session MUST NOT be reused once CLOSED. An implementation MUST release the
  resources associated with the session (e.g. closing a socket it owns exclusively, discarding
  registered callbacks); resources shared with other sessions are released only when no longer used.

The state machine is driven purely by locally observed events (messages sent or received, local
timers); there is no shared or negotiated state between peers beyond what these messages convey.

## 6. Handshake procedure

The handshake is intentionally minimal and symmetric: both peers execute identical logic, and there is
no distinguished initiator or responder role at the protocol level.

1. **Each side independently** sends its own handshake probe carrying its own protocol version:
   `[0x01, VERSION]`. Sending this probe is unconditional — it is not sent in reply to anything, but as
   part of initiating the session on that side. Both peers do this concurrently; neither waits for the
   other's probe before sending its own. Implementations conforming to **this revision** MUST send
   `VERSION = 0x00` (see [Section 13](#13-conformance)).
2. On receiving a well-formed `[0x01, VERSION]` while in CREATED, HANDSHAKING, or OPEN, a peer MUST
   reply with a handshake acknowledgment `[0x02]`, and SHOULD do so immediately. This applies to
   **every** received probe, including duplicates and probes received after the local peer has already
   reached OPEN: the counterpart's own transition depends on receiving at least one acknowledgment, and
   any individual acknowledgment may be lost. Receiving a probe while OPEN does not change the local
   state. A probe received while in CLOSING or CLOSED is not acknowledged.
3. On receiving `[0x02]` while in HANDSHAKING, a peer transitions to OPEN. A `[0x02]` received in any
   other state is discarded. Because both sides send their own probe independently (step 1), each
   side's probe triggers an ack from the other, allowing both sides to reach OPEN.
4. **Retransmission.** Because UDP is unreliable, a peer MUST retransmit its handshake probe while in
   HANDSHAKING, at a bounded interval (RECOMMENDED initial interval: 500 ms), until it reaches OPEN or
   its handshake timeout or attempt budget is exhausted.
5. For NAT-traversal scenarios, where a fixed-interval attempt window may not suffice to align both
   peers' NAT mappings, a peer SHOULD use exponential backoff (RECOMMENDED: doubling the interval, capped
   at 8 s), bounded by a maximum attempt count. Expiry of the handshake timeout, or exhaustion of the
   attempt budget, without reaching OPEN moves the session to CLOSED and MUST be reported to the caller
   as a distinct, non-exceptional outcome (e.g. via a callback or status value), not as an error.
6. **Implicit confirmation.** Because a conforming peer only sends Data (`0x00`) or Keep-alive (`0x05`)
   while its own session is OPEN, receiving either of these while in HANDSHAKING proves that the
   counterpart has reached OPEN, which is only possible if it received the local peer's probe and the
   local peer received its probe or is about to. A peer that receives `0x00` or `0x05` while in
   HANDSHAKING MUST treat this as equivalent to receiving `[0x02]` and transition to OPEN; a received
   Data message is then delivered to the application normally. This covers the case where every
   acknowledgment to the local peer was lost while the counterpart's subsequent traffic was not.
7. A peer that reaches OPEN SHOULD send one Keep-alive (`[0x05]`) promptly (RECOMMENDED: immediately)
   unless it sends Data first. Together with steps 2 and 6 this lets the counterpart confirm the
   handshake without waiting for the regular keep-alive interval.
8. A peer that receives `[0x03]` (Closing) or `[0x04]` (Closed) while in HANDSHAKING MUST NOT
   transition to OPEN as a result; it handles the message per [Section 8](#8-connection-termination)
   and the session ends in CLOSED.
9. The `VERSION` byte carried in the probe is a **declarative** identifier of the sender's protocol
   version; it is not negotiated, and the acknowledgment does not echo it. A `VERSION` value different
   from the local peer's own does not by itself block or alter the handshake. An implementation MAY,
   as a local policy, refuse to proceed with a peer whose `VERSION` it does not support, by sending
   `[0x04]` and moving to CLOSED (reported to the caller as a version-mismatch outcome). It MUST NOT
   derive security-relevant behavior from the value (see [Section 12](#12-security-considerations)).
   Beyond this byte, the handshake carries no capability or key negotiation.

Sequence diagram (happy path — both peers send their own probe independently, per step 1):

```
Peer A                                Peer B
  |---- [0x01, VERSION] handshake ---->|
  |<--- [0x01, VERSION] handshake -----|   (B's own probe, sent independently)
  |                                    |
  |<--- [0x02] ack --------------------|   (B acks A's probe)
  |---- [0x02] ack ------------------->|   (A acks B's probe)
  |                                    |
  | (A: HANDSHAKING -> OPEN)           | (B: HANDSHAKING -> OPEN)
  |---- [0x05] keep-alive ------------>|   (step 7)
  |<--- [0x05] keep-alive -------------|
  |======== both peers OPEN ===========|
```

In practice the exact interleaving of probes and acknowledgments varies. A conforming implementation
MUST tolerate duplicate probes and acknowledgments arriving in any order or multiplicity.

## 7. Keep-alive and liveness

Once a session is OPEN, a peer SHOULD periodically send a keep-alive message (`[0x05]`) to signal
liveness and to keep NAT mappings open. A conforming implementation:

- sends keep-alive only while the session is OPEN;
- MAY suppress a scheduled keep-alive if a Data message has been sent within the current keep-alive
  interval, since Data equally signals liveness;
- MUST treat failures in local keep-alive processing as non-fatal to the session.

An endpoint MAY be configured with a **liveness timeout**, applied in the OPEN and CLOSING states: if
no message of any kind has been received from the peer for this duration, the session is considered
unresponsive. On expiry:

- the endpoint SHOULD terminate the session with an abortive close (Section 8: send `[0x04]`
  best-effort and move to CLOSED), without waiting for any message from the peer;
- the timer MUST be reset on receipt of **any** well-formed message from the peer, not only keep-alive;
- this is a purely local, unilateral decision — the peer learns of it only through the `Closed`
  message, which it may never receive if it truly is unreachable.

The handshake has its own timeout (Section 6, steps 4–5); the liveness timeout does not apply in
HANDSHAKING.

As a RECOMMENDED starting point (a local configuration default, not a protocol constant), a liveness
timeout of **60 seconds** paired with a keep-alive interval of **15 seconds** gives the peer three to
four opportunities to be heard from before the session is declared unresponsive. When either value is
changed, the keep-alive interval SHOULD remain roughly a quarter to a third of the liveness timeout.
Because many NATs expire idle UDP mappings after 30 seconds or less, a keep-alive interval above
25 seconds is NOT RECOMMENDED for sessions crossing a NAT.

Since a peer's keep-alive interval is not known to its counterpart, a liveness timeout shorter than
about three times the peer's expected keep-alive interval risks closing healthy sessions; endpoints
that disable keep-alive SHOULD document this so that their counterparts can configure accordingly.

## 8. Connection termination

Two termination messages exist:

- **Closing** (`[0x03]`): a request for a graceful close.
- **Closed** (`[0x04]`): the final close — either the confirmation of a received `Closing`, or an
  abortive close sent unilaterally.

**Graceful close (initiator).** To close a session that is OPEN, a peer sends `[0x03]` and enters
CLOSING. While in CLOSING it SHOULD retransmit `[0x03]` at a bounded interval (RECOMMENDED: 500 ms)
until it receives `[0x04]` or a **closing timeout** expires (RECOMMENDED: 3 s). On receipt of `[0x04]`
it moves to CLOSED. On expiry of the closing timeout it sends `[0x04]` once, best-effort, and moves to
CLOSED.

**Graceful close (responder).** A peer that receives `[0x03]` while in HANDSHAKING or OPEN MUST reply
with `[0x04]`, SHOULD surface a "closing"/"closed" notification to the application, and moves to
CLOSED. A peer that receives `[0x03]` while itself in CLOSING (simultaneous close) MUST reply with
`[0x04]` and moves to CLOSED.

**Abortive close.** A peer MAY at any time before CLOSED (including during HANDSHAKING, on handshake
failure, on liveness timeout, or on local shutdown) send `[0x04]` once, best-effort, and move directly
to CLOSED.

**Receiving Closed.** A peer that receives `[0x04]` in HANDSHAKING, OPEN, or CLOSING MUST move to
CLOSED and SHOULD surface a "closed" notification to the application. It MUST NOT reply.

**Common rules.**

- Once CLOSED, a peer MUST NOT send or process any further message for this session (late
  retransmissions of `[0x03]` from the peer are therefore not answered; the peer's own closing timeout
  covers this case), and MUST release the session's resources.
- Closure MUST be idempotent: a repeated close request on a session that is CLOSING or CLOSED MUST NOT
  raise an error, and on a CLOSED session MUST NOT cause any message to be sent.
- Failure to transmit `[0x03]` or `[0x04]` (e.g. because the underlying transport is already
  unavailable) MUST be tolerated rather than propagated as an error; the local side proceeds with
  teardown regardless.

Sequence diagram (graceful close):

```
Peer A                                Peer B
  |---- [0x03] closing --------------->|   (A: OPEN -> CLOSING)
  |<--- [0x04] closed -----------------|   (B: OPEN -> CLOSED)
  | (A: CLOSING -> CLOSED)             |
```

## 9. Payload compression

**Compression is not part of SHSP.** SHSP defines no compression mechanism, codec, or encoding
convention for the Data message body; the body is opaque application payload, transmitted and
delivered byte-for-byte (Section 4). SHSP MUST NOT interpret, transform, or assume any particular
encoding of this payload.

An application that wants its data compressed on the wire compresses the payload itself before handing
it to SHSP, and decompresses it after receiving it from SHSP; from SHSP's point of view the compressed
bytes are simply the Data message body. Codec choice, and any agreement between the two ends of a
session on which codec (if any) is in use, is entirely an application-layer concern, out of scope of
this specification.

## 10. Error handling

The following conditions are defined by this specification and SHOULD be preserved by any conforming
implementation:

| Condition | Behavior |
|---|---|
| Zero-byte datagram received | Discarded |
| Unrecognized message type prefix | Discarded; MAY be logged; session state unaffected |
| Handshake missing the mandatory `VERSION` byte (1-byte datagram) | Malformed; discarded |
| Extra bytes after `VERSION`, or body on a control message | Extra bytes ignored; message processed normally |
| Any message other than Handshake (`0x01`) received in CREATED | Discarded |
| Handshake-Ack (`0x02`) received outside HANDSHAKING | Discarded |
| Handshake (`0x01`) received in OPEN | Acknowledged with `0x02`; state unchanged |
| Data (`0x00`) or Keep-alive (`0x05`) received in HANDSHAKING | Implicit confirmation; transition to OPEN (Section 6, step 6) |
| Closing (`0x03`) received in HANDSHAKING, OPEN, or CLOSING | Reply `0x04`; transition to CLOSED |
| Closed (`0x04`) received in HANDSHAKING, OPEN, or CLOSING | Transition to CLOSED; no reply |
| Any message received for a CLOSED session | Discarded; no processing |
| Data send attempted while not OPEN (CREATED, HANDSHAKING) | Send rejected: session not open |
| Data send attempted while CLOSING | Send rejected: session is closing |
| Data send attempted on a CLOSED session | Send rejected: session is closed |
| Data send with empty or oversized application payload (Section 3) | Validation error; message not sent |
| Handshake timeout or retries exhausted without opening | Session CLOSED; distinct non-exceptional outcome reported |
| Closing timeout expired without receiving `0x04` | Best-effort `0x04` sent; session CLOSED; no error |
| Double close / close of an already-closed session | No-op (idempotent) |

Implementation notes (non-normative): local API conditions such as binding to an out-of-range port,
sending with no local socket bound for the destination's address family, or a transport reporting
zero bytes written are local errors outside the scope of the wire protocol; implementations are
encouraged to report them as distinct error types.

The handshake carries a `VERSION` byte (Section 6), but it is **declarative only — there is no
on-the-wire version negotiation, by design** (see
[Section 11.2](#112-version-compatibility-is-not-negotiated-by-design)).

## 11. Known limitations

### 11.1 Explicit non-goals

The following capabilities are **intentionally out of scope** of SHSP. Responsibility for them belongs
to any protocol layered above SHSP, which is expected to run its own handshake/exchange once the SHSP
session is open:

- **Peer authentication / nonce signing**: verifying that a peer is who it claims to be (e.g. by
  signing a nonce with a private key) is not a concern of SHSP and is out of scope of this
  specification.
- **NAT/address signaling**: exchanging public/local addresses, keys, or timing windows between peers
  is not a concern of SHSP beyond the incidental NAT-punching side effect of the handshake probe
  (Section 1).
- **Address-discovery (STUN-like) and relay (TURN-like) mechanisms**: SHSP does not provide address
  discovery or relay/fallback for peers that cannot establish a direct UDP path (e.g. behind symmetric
  NATs). This is left to whatever layer supplies SHSP with a destination address.

### 11.2 Version compatibility is not negotiated, by design

Version compatibility in SHSP is a property of the specific pair of versions involved, not a
protocol-mediated outcome. There is deliberately **no negotiation**: a session either opens — because
the two implementations are wire-compatible enough to complete the handshake and exchange data — or it
does not. `VERSION` (Section 6) lets a peer observe which revision its counterpart implements, and a
local policy MAY refuse unsupported versions (Section 6, step 9), but SHSP itself does not detect,
report, or resolve a mismatch. Future revisions SHOULD remain compatible with the extensibility rules
of Section 4 (ignored trailing bytes) so that older receivers keep working.

### 11.3 No session identifier on the wire

A session is identified only by the peers' (address, port) pair; messages carry no session identifier,
nonce, or epoch. Consequences, accepted in this revision for simplicity:

- **Stale messages.** Delayed datagrams from a previous session between the same address/port pair
  (e.g. a late `0x02`, `0x00`, `0x05`, or `0x04`) cannot be distinguished from messages of a new
  session and may spuriously open or close it. Endpoints SHOULD NOT start a new session with the same
  peer address/port pair for a quiet period after the previous one reached CLOSED (RECOMMENDED: at
  least the closing timeout plus the maximum expected path delay, e.g. 5 s), and SHOULD prefer a fresh
  local port for a new session when practical.
- **Peer restart.** If a peer restarts and opens a new session from the same address/port while the
  other side is still OPEN, the other side simply acknowledges the new probes (Section 6, step 2) and
  both sides end up OPEN, but the surviving side cannot tell that its counterpart lost all previous
  session context. Applications needing to detect this SHOULD run their own session-level exchange
  after the SHSP session opens.
- **NAT rebinding.** If a NAT changes the peer's public port mid-session, its messages arrive from a
  new address/port pair and are not associated with the existing session, which eventually expires
  through the liveness timeout (Section 7).

A future revision MAY address these by adding a session identifier to the Handshake body, which the
extensibility rules of Section 4 allow without breaking receivers of this revision.

## 12. Security considerations

The protocol as specified provides **no confidentiality, integrity, or authentication guarantees**:

- Any host able to send UDP packets to a listening endpoint can send handshake, data, or close
  messages; the protocol provides no mechanism to verify that a peer is who it claims to be.
- Data payloads are sent in the clear.
- Because no message carries a nonce or session identifier (Section 11.3), an attacker able to spoof
  the peer's address/port can complete a handshake with a single forged `0x02` (or `0x00`/`0x05`), close
  a session with a forged `0x04` or `0x03`, inject Data, or keep a dead session alive by resetting the
  liveness timeout (Section 7). Applications relying on the liveness timeout for resource reclamation
  SHOULD NOT treat it as a security control.
- **Resource exhaustion.** An endpoint that accepts sessions from previously unknown peers allocates
  state on receipt of a single (possibly spoofed) probe. Such an endpoint SHOULD bound the number of
  concurrent sessions in HANDSHAKING (globally and per source address) and SHOULD apply the handshake
  timeout to sessions created by an incoming probe, so that unanswered half-open sessions are reclaimed.
- **Reflection.** Every response defined by SHSP (`0x02`, `0x04`) is no larger than the message that
  triggered it, so SHSP offers no amplification factor for reflection attacks. Implementations MUST NOT
  add responses that are larger than their trigger.
- The `VERSION` byte is sent in the clear and is trivially observable or forgeable. No
  security-relevant decision, negotiation, or downgrade path MAY be driven by its value, at the SHSP
  layer or by any protocol layered above it.
- Applications requiring confidentiality, integrity, or peer authentication MUST implement these at a
  layer above SHSP (e.g. by encrypting the payload before it is handed to SHSP, and running their own
  authenticated handshake once the SHSP session is open). This is a permanent property of SHSP (see
  [Section 11.1](#111-explicit-non-goals)).

## 13. Conformance

This section states, in one place, what an implementation MUST do to be a conformant implementation of
**this revision** of SHSP.

**Mandatory (interoperability-critical) — a conformant implementation MUST:**

- Use the six message prefixes exactly as defined in [Section 4](#4-wire-format) (`0x00`–`0x05`),
  discard messages with any other prefix, and ignore trailing bytes as specified there.
- Send `VERSION = 0x00` in every handshake probe, and discard as malformed a probe with no `VERSION`
  byte.
- Implement the state machine of [Section 5](#5-connection-states) with the transitions defined in
  Sections 6, 7, and 8.
- Retransmit its handshake probe while in HANDSHAKING (Section 6, step 4).
- Acknowledge every well-formed probe received in CREATED, HANDSHAKING, or OPEN (Section 6, step 2).
- Treat Data or Keep-alive received in HANDSHAKING as implicit confirmation (Section 6, step 6).
- Tolerate duplicate or out-of-order handshake probes and acknowledgments.
- Reject Data sends with an empty or oversized application payload ([Section 3](#3-transport)).
- Treat the Data message body as opaque application bytes ([Section 9](#9-payload-compression)).
- Handle `Closing` and `Closed` as defined in [Section 8](#8-connection-termination): reply `0x04` to a
  received `0x03`, accept `0x04` in any non-CLOSED state, bound CLOSING with a timeout, treat closure as
  idempotent, stop sending Data/Keep-alive once CLOSING, and stop sending or processing any message and
  release associated resources once CLOSED.

Two conformant implementations that satisfy the mandatory list above, and between which UDP datagrams
can be delivered in both directions within their configured handshake timeouts, will open a session and
be able to exchange Data messages.

**Local/configurable (not interoperability-critical) — a conformant implementation MAY vary:**

- Handshake retransmission interval and strategy (fixed-interval or exponential backoff), and their
  timeout/attempt-budget values (Section 6).
- Closing retransmission interval and closing timeout (Section 8).
- Keep-alive interval, and whether a liveness timeout is configured, together with its duration
  (Section 7), subject to the guidance given there.
- Local policy on unsupported `VERSION` values (Section 6, step 9).
- Whatever the application does to the Data payload before/after handing it to SHSP (Section 9).

None of the items in this second list need to match between the two peers for the session to
interoperate at the SHSP level, provided the timing guidance of Section 7 is respected.

## 14. Versioning

- This document specifies the wire format, state machine, and required behavior of SHSP independently
  of any single implementation's release cadence.
- The handshake carries a declarative `VERSION` byte (Section 6). Implementations of this revision MUST
  use `VERSION = 0x00`. This value identifies the revision but is not used for on-the-wire negotiation
  (Section 11.2).
- A future revision that changes wire-visible, interoperability-critical behavior (the mandatory list in
  Section 13) MUST increment `VERSION`. A revision that only clarifies wording or adjusts
  locally-configurable defaults MAY keep `VERSION` unchanged.
- Changes to wire-visible behavior SHOULD be reflected in this document, with a revision note added
  below.

### Revision notes

- **Draft, VERSION 0x00 (current)**: handshake acknowledgment made mandatory for every received probe
  (including after OPEN); implicit confirmation and probe retransmission made mandatory; prompt
  keep-alive after OPEN; graceful close redefined as a `Closing`/`Closed` exchange with retransmission
  and closing timeout; unknown prefixes discarded instead of raised as errors; trailing-byte
  extensibility rule; per-family size limits; documented absence of a session identifier. Since this
  revision is still a draft, `VERSION` remains `0x00`.

## 15. References

### Normative references

- [RFC 768] Postel, J., "User Datagram Protocol", STD 6, RFC 768, August 1980.
- [RFC 2119] Bradner, S., "Key words for use in RFCs to Indicate Requirement Levels", BCP 14,
  RFC 2119, March 1997.
- [RFC 8174] Leiba, B., "Ambiguity of Uppercase vs Lowercase in RFC 2119 Key Words", BCP 14,
  RFC 8174, May 2017.

### Informative references

- [RFC 8085] Eggert, L., Fairhurst, G., and G. Shepherd, "UDP Usage Guidelines", BCP 145, RFC 8085,
  March 2017.
- [RFC 4787] Audet, F. and C. Jennings, "Network Address Translation (NAT) Behavioral Requirements for
  Unicast UDP", BCP 127, RFC 4787, January 2007.

This document does not bind its normative text to any single implementation's source layout.
Implementers seeking a concrete reference should consult the accompanying implementation's handshake,
state-machine, and message-dispatch modules, and its changelog for the history of removed or
superseded mechanisms.
