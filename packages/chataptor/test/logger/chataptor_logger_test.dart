import 'package:chataptor/src/logger/chataptor_logger.dart';
import 'package:test/test.dart';

void main() {
  test('ChataptorLogLevel ordering', () {
    expect(ChataptorLogLevel.values, [
      ChataptorLogLevel.debug,
      ChataptorLogLevel.info,
      ChataptorLogLevel.warn,
      ChataptorLogLevel.error,
    ]);
  });

  test('NoOpChataptorLogger discards everything', () {
    final logger = const NoOpChataptorLogger();
    // Must not throw.
    logger.log(ChataptorLogLevel.debug, 'x');
    logger.log(ChataptorLogLevel.error, 'x', error: Exception('boom'));
  });

  test('RecordingChataptorLogger collects entries (for tests)', () {
    final logger = RecordingChataptorLogger();
    logger.log(ChataptorLogLevel.info, 'hello');
    logger.log(ChataptorLogLevel.warn, 'careful');
    expect(logger.entries, hasLength(2));
    expect(logger.entries[0].level, ChataptorLogLevel.info);
    expect(logger.entries[1].message, 'careful');
  });
}
