import 'package:chataptor/src/config/translation_config.dart';
import 'package:test/test.dart';

void main() {
  test('TranslationConfig.auto with explicit language', () {
    final config = TranslationConfig.auto(customerLanguage: 'pl');
    expect(config.enabled, isTrue);
    expect(config.customerLanguage, 'pl');
  });

  test('TranslationConfig.auto without language uses null (runtime detect)', () {
    final config = TranslationConfig.auto();
    expect(config.enabled, isTrue);
    expect(config.customerLanguage, isNull);
  });

  test('TranslationConfig.disabled is disabled', () {
    final config = TranslationConfig.disabled();
    expect(config.enabled, isFalse);
    expect(config.customerLanguage, isNull);
  });

  test('copyWith', () {
    final config = TranslationConfig.auto(customerLanguage: 'en');
    final updated = config.copyWith(customerLanguage: 'de');
    expect(updated.customerLanguage, 'de');
    expect(updated.enabled, isTrue);
  });
}
