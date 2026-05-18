/// Chataptor — pure-Dart core client for real-time multilingual customer
/// support chat.
///
/// Pair with `package:chataptor_flutter` for drop-in widgets. Use this
/// package directly for headless / custom-UI integrations.
library chataptor;

// Auth
export 'src/auth/customer_identity.dart';

// Client
export 'src/client/chataptor_client.dart';
export 'src/client/connection_state.dart';
export 'src/client/send_result.dart';

// Config
export 'src/config/chataptor_config.dart';
export 'src/config/feature_toggles.dart';
export 'src/config/push_config.dart';
export 'src/config/site_config.dart';
export 'src/config/translation_config.dart';
export 'src/config/transport_config.dart';

// Errors
export 'src/errors/chataptor_error.dart';

// Hooks
export 'src/hooks/chataptor_hooks.dart';

// HTTP
export 'src/http/chataptor_http_client.dart';

// Logger
export 'src/logger/chataptor_logger.dart'
    show ChataptorLogLevel, ChataptorLogger, NoOpChataptorLogger;

// Models
export 'src/models/agent_info.dart';
export 'src/models/attachment.dart';
export 'src/models/conversation.dart';
export 'src/models/enums.dart';
export 'src/models/message.dart';
export 'src/models/message_draft.dart';

// Storage
export 'src/storage/chataptor_storage.dart';

// Transport — public port ONLY. Concrete event/push/state types stay in
// `testing.dart` because they are scripting-only surface.
export 'src/transport/chat_transport.dart' show ChatTransport;
