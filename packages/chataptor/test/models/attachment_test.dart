import 'package:chataptor/src/models/attachment.dart';
import 'package:chataptor/src/models/enums.dart';
import 'package:test/test.dart';

void main() {
  test('Attachment equality and copyWith', () {
    const a = Attachment(
      id: 'a1',
      url: 'https://cdn/a.png',
      fileName: 'a.png',
      type: AttachmentType.image,
      sizeBytes: 1024,
    );
    const b = Attachment(
      id: 'a1',
      url: 'https://cdn/a.png',
      fileName: 'a.png',
      type: AttachmentType.image,
      sizeBytes: 1024,
    );
    expect(a, b);

    final c = a.copyWith(sizeBytes: 2048);
    expect(c.sizeBytes, 2048);
    expect(c.id, 'a1');
  });
}
