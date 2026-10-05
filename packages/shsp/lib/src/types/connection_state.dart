/// Explicit connection state machine for a SHSP session (Section 5 of the spec).
///
/// ```
/// CREATED -> HANDSHAKING -> OPEN -> CLOSING (optional) -> CLOSED
/// ```
///
/// - [created]: session exists; no handshake message sent or received yet. A message with any
///   prefix other than a Handshake probe (`0x01`) received while in this state MUST be discarded.
/// - [handshaking]: at least one handshake probe has been sent and/or received, but the session
///   is not yet open.
/// - [open]: the handshake has been confirmed by receipt of an acknowledgment. Data messages MAY
///   be sent and received; keep-alive is active.
/// - [closing]: a soft-close has been announced, locally or by the peer. No further Data or
///   Keep-alive messages may be sent, but incoming messages continue to be received and processed.
/// - [closed]: a final close has been sent or received. No further messages may be sent and no
///   further incoming messages for this session may be processed; the session MUST NOT be reused.
enum ShspConnectionState { created, handshaking, open, closing, closed }
