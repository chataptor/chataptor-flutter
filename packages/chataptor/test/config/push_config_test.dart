import 'package:chataptor/src/config/push_config.dart';
import 'package:test/test.dart';

void main() {
  test('PushConfig.disabled is disabled', () {
    final config = PushConfig.disabled();
    expect(config.mode, PushMode.disabled);
  });

  test('PushConfig.hookIn mode', () {
    final config = PushConfig.hookIn();
    expect(config.mode, PushMode.hookIn);
  });

  test('PushPlatform values include fcm and apnsDirect', () {
    expect(PushPlatform.values, contains(PushPlatform.fcm));
    expect(PushPlatform.values, contains(PushPlatform.apnsDirect));
  });
}
