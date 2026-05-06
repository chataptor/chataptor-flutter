import 'package:chataptor/src/config/feature_toggles.dart';
import 'package:chataptor/src/models/enums.dart';
import 'package:test/test.dart';

void main() {
  test('FeatureToggles defaults', () {
    const toggles = FeatureToggles();
    expect(toggles.typingIndicators, isTrue);
    expect(toggles.readReceipts, isTrue);
    expect(toggles.emojiSubstitution, isTrue);
    // Attachments are a v0.4.0 feature. Disabled by default in v0.1.0 so no
    // composer widget advertises a picker that does not exist.
    expect(toggles.attachments.enabled, isFalse);
  });

  test('AttachmentConfig v0.1.0 default is disabled', () {
    const attach = AttachmentConfig();
    expect(attach.enabled, isFalse);
    expect(attach.maxSizeMB, 10);
    expect(attach.allowedTypes, {
      AttachmentType.image,
      AttachmentType.document,
    });
  });

  test('AttachmentConfig can be enabled explicitly (v0.4.0 path)', () {
    const attach = AttachmentConfig(enabled: true);
    expect(attach.enabled, isTrue);
  });

  test('copyWith', () {
    const toggles = FeatureToggles();
    final updated = toggles.copyWith(typingIndicators: false);
    expect(updated.typingIndicators, isFalse);
    expect(updated.readReceipts, isTrue);
  });
}
