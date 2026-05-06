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
    // Must not throw.
    const NoOpChataptorLogger()
      ..log(ChataptorLogLevel.debug, 'x')
      ..log(ChataptorLogLevel.error, 'x', error: Exception('boom'));
  });

  test('RecordingChataptorLogger collects entries (for tests)', () {
    final logger = RecordingChataptorLogger()
      ..log(ChataptorLogLevel.info, 'hello')
      ..log(ChataptorLogLevel.warn, 'careful');
    expect(logger.entries, hasLength(2));
    expect(logger.entries[0].level, ChataptorLogLevel.info);
    expect(logger.entries[1].message, 'careful');
  });
}
