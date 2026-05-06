import 'package:chataptor/src/auth/customer_identity.dart';
import 'package:test/test.dart';

void main() {
  group('CustomerIdentity', () {
    test('anonymous has no identifying fields and isAnonymous', () {
      const id = CustomerIdentity.anonymous();
      expect(id.id, isNull);
      expect(id.email, isNull);
      expect(id.name, isNull);
      expect(id.isAnonymous, isTrue);
      expect(id.isVerified, isFalse);
    });

    test('identified with email is not anonymous', () {
      const id = CustomerIdentity(email: 'a@b.c', name: 'Anna');
      expect(id.isAnonymous, isFalse);
      expect(id.isVerified, isFalse);
    });

    test('identified with verificationHash is verified', () {
      const id = CustomerIdentity(
        id: 'u-1',
        email: 'a@b.c',
        verificationHash: 'deadbeef',
      );
      expect(id.isVerified, isTrue);
      expect(id.isAnonymous, isFalse);
    });

    test('copyWith overrides fields', () {
      const id = CustomerIdentity(email: 'a@b.c');
      final updated = id.copyWith(name: 'Anna');
      expect(updated.email, 'a@b.c');
      expect(updated.name, 'Anna');
    });

    test('equality compares every field', () {
      const a = CustomerIdentity(email: 'a@b.c', name: 'Anna');
      const b = CustomerIdentity(email: 'a@b.c', name: 'Anna');
      const c = CustomerIdentity(email: 'a@b.c');
      expect(a, b);
      expect(a, isNot(c));
    });
  });
}
