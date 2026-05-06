import 'package:chataptor/src/client/send_result.dart';
import 'package:chataptor/src/errors/chataptor_error.dart';
import 'package:chataptor/src/models/message_draft.dart';
import 'package:test/test.dart';

void main() {
  group('MessageDraft', () {
    test('copyWith overrides specified fields', () {
      const draft = MessageDraft(body: 'hi');
      final updated = draft.copyWith(body: 'hello', metadata: {'k': 'v'});
      expect(updated.body, 'hello');
      expect(updated.metadata, {'k': 'v'});
    });

    test('equality and hashCode', () {
      const a = MessageDraft(body: 'x');
      const b = MessageDraft(body: 'x');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('SendResult', () {
    test('SendSuccess carries a draft', () {
      const draft = MessageDraft(body: 'ok');
      const result = SendSuccess(draft);
      expect(result.draft, draft);
    });

    test('SendFailure carries error and pending draft', () {
      const draft = MessageDraft(body: 'retry me');
      const err = NetworkError('offline');
      const result = SendFailure(err, draft);
      expect(result.error, err);
      expect(result.pending, draft);
    });

    test('pattern match is exhaustive', () {
      String kind(SendResult r) => switch (r) {
        SendSuccess() => 'ok',
        SendFailure() => 'fail',
      };

      expect(kind(const SendSuccess(MessageDraft(body: 'x'))), 'ok');
      expect(
        kind(
          const SendFailure(
            NetworkError('x'),
            MessageDraft(body: 'x'),
          ),
        ),
        'fail',
      );
    });
  });
}
