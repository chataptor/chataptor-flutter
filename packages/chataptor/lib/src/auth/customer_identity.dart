import 'package:meta/meta.dart';

/// Identifies the customer on whose behalf the SDK is communicating with
/// Chataptor.
///
/// Three modes are supported:
///
/// 1. **Anonymous** — [CustomerIdentity.anonymous]. The SDK generates and
///    persists a guest ID under the hood; the server stitches together
///    conversation history for that guest ID across sessions on the same
///    device.
///
/// 2. **Identified (unverified)** — populate [id], [email], and/or [name] but
///    leave [verificationHash] null. Useful when the merchant knows the user
///    client-side (e.g., from their own login) but has no server-side secret
///    to sign with.
///
/// 3. **Identified (verified)** — same as above, plus a [verificationHash]
///    computed by the merchant's backend as
///    `HMAC-SHA256(email, site.api_key)`, hex-encoded. The server marks
///    conversations from a verified identity with `verified: true` and
///    surfaces that bit to agents.
@immutable
class CustomerIdentity {
  /// Creates an identified [CustomerIdentity]. Any of [id], [email], [name],
  /// or [verificationHash] may be null.
  const CustomerIdentity({
    this.id,
    this.email,
    this.name,
    this.verificationHash,
    this.customData = const {},
  });

  /// Creates an anonymous identity. The SDK will allocate a stable guest ID
  /// on first use.
  const CustomerIdentity.anonymous()
    : id = null,
      email = null,
      name = null,
      verificationHash = null,
      customData = const {};

  /// Merchant-supplied stable ID for this customer (e.g., user row PK).
  final String? id;

  /// Customer email address.
  final String? email;

  /// Display name shown to agents.
  final String? name;

  /// HMAC-SHA256 of [email] using the site's API key, hex-lowercase.
  /// When present, the server treats this identity as verified.
  final String? verificationHash;

  /// Arbitrary merchant data passed through to the server (custom fields,
  /// CRM linkage, etc.).
  final Map<String, dynamic> customData;

  /// Whether the identity has a [verificationHash].
  bool get isVerified => verificationHash != null;

  /// Whether no identifying fields were supplied (the SDK will use a guest
  /// ID).
  bool get isAnonymous => id == null && email == null;

  /// Returns a copy with the given fields overridden.
  CustomerIdentity copyWith({
    String? id,
    String? email,
    String? name,
    String? verificationHash,
    Map<String, dynamic>? customData,
  }) {
    return CustomerIdentity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      verificationHash: verificationHash ?? this.verificationHash,
      customData: customData ?? this.customData,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CustomerIdentity &&
      other.id == id &&
      other.email == email &&
      other.name == name &&
      other.verificationHash == verificationHash &&
      _mapEquals(other.customData, customData);

  @override
  int get hashCode =>
      Object.hash(id, email, name, verificationHash, _mapHash(customData));
}

bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (!b.containsKey(e.key) || b[e.key] != e.value) return false;
  }
  return true;
}

int _mapHash(Map<String, dynamic> m) {
  var h = 0;
  for (final e in m.entries) {
    h = h ^ Object.hash(e.key, e.value);
  }
  return h;
}
