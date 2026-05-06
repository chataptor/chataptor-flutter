import 'package:chataptor/src/models/enums.dart';
import 'package:meta/meta.dart';

/// A file attached to a [Message].
@immutable
class Attachment {
  /// Creates an [Attachment].
  const Attachment({
    required this.id,
    required this.url,
    required this.fileName,
    required this.type,
    required this.sizeBytes,
    this.thumbnailUrl,
    this.mimeType,
  });

  /// Server-assigned attachment ID.
  final String id;

  /// URL to fetch the attachment content.
  final String url;

  /// Original file name (as uploaded).
  final String fileName;

  /// Coarse type classification.
  final AttachmentType type;

  /// Size in bytes.
  final int sizeBytes;

  /// URL of a smaller preview/thumbnail, if generated server-side.
  final String? thumbnailUrl;

  /// IANA MIME type (e.g. `image/png`), if known.
  final String? mimeType;

  /// Returns a copy with the given fields overridden.
  Attachment copyWith({
    String? id,
    String? url,
    String? fileName,
    AttachmentType? type,
    int? sizeBytes,
    String? thumbnailUrl,
    String? mimeType,
  }) {
    return Attachment(
      id: id ?? this.id,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      type: type ?? this.type,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      mimeType: mimeType ?? this.mimeType,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Attachment &&
      other.id == id &&
      other.url == url &&
      other.fileName == fileName &&
      other.type == type &&
      other.sizeBytes == sizeBytes &&
      other.thumbnailUrl == thumbnailUrl &&
      other.mimeType == mimeType;

  @override
  int get hashCode =>
      Object.hash(id, url, fileName, type, sizeBytes, thumbnailUrl, mimeType);
}
