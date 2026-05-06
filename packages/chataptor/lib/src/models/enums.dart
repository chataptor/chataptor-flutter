/// Who authored a `Message`.
enum MessageAuthor {
  /// The end customer — the host app's user.
  customer,

  /// A Chataptor agent (support operator).
  agent,

  /// An automated bot (chatbot builder, AI autopilot).
  bot,
}

/// Rich type of message content.
enum MessageType {
  /// Plain text body.
  text,

  /// Bot-generated quick-reply button set. Selections route back via the
  /// `selectQuickReply` client method.
  quickReplies,

  /// Bot-generated card carousel. Button clicks route via
  /// `selectCarouselButton`.
  carousel,
}

/// Delivery status of a message from the customer's perspective.
enum MessageStatus {
  /// Queued locally, not yet acknowledged by the server.
  pending,

  /// Accepted by the server.
  sent,

  /// Delivered to the agent workspace.
  delivered,

  /// An agent read the message.
  read,

  /// Send failed after retries — surfaced via `SendFailure`.
  failed,
}

/// Which transport actually delivered a message to its destination.
enum DeliveryChannel {
  /// Real-time delivery over Phoenix Channels WebSocket.
  websocket,

  /// Fallback delivery via email threading.
  email,

  /// REST API (e.g., legacy integrations or out-of-band automation).
  api,
}

/// Coarse content type of an `Attachment`.
enum AttachmentType {
  /// Raster image (png, jpg, webp, …).
  image,

  /// Document (pdf, doc, txt, …).
  document,

  /// Audio file.
  audio,

  /// Video file.
  video,
}

/// Lifecycle status of a `Conversation`.
enum ConversationStatus {
  /// Conversation is ongoing and can receive new messages.
  open,

  /// Conversation was closed by agent or customer.
  closed,
}

/// Which surfaces are active on a `Conversation`. A `hybrid` conversation may
/// receive messages over chat AND email.
enum ChannelType {
  /// Chat-only.
  chat,

  /// Email-only.
  email,

  /// Both chat and email.
  hybrid,
}
