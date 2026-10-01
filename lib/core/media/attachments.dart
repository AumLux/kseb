import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../errors/app_failure.dart';
import '../location/location_service.dart';
import '../outbox/file_bytes.dart';
import '../outbox/outbox.dart';
import '../supabase/providers.dart';

/// A file attached to a record (`attachments` table). Visibility follows the
/// owning record via RLS.
class Attachment {
  const Attachment({
    required this.id,
    required this.ownerTable,
    required this.ownerId,
    required this.storagePath,
    required this.mimeType,
    required this.kind,
    required this.createdAt,
    this.fileName,
    this.capturedAt,
  });

  final String id;
  final String ownerTable;
  final String ownerId;
  final String storagePath;
  final String mimeType;
  final String kind;
  final DateTime createdAt;
  final String? fileName;
  final DateTime? capturedAt;

  bool get isImage => mimeType.startsWith('image/');

  factory Attachment.fromJson(Map<String, dynamic> j) => Attachment(
        id: j['id'] as String,
        ownerTable: j['owner_table'] as String,
        ownerId: j['owner_id'] as String,
        storagePath: j['storage_path'] as String,
        mimeType: j['mime_type'] as String,
        kind: j['kind'] as String,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
        fileName: j['file_name'] as String?,
        capturedAt: j['captured_at'] == null ? null : DateTime.parse(j['captured_at'] as String).toLocal(),
      );
}

typedef AttachmentOwner = ({String table, String id});

final attachmentsProvider = FutureProvider.autoDispose.family<List<Attachment>, AttachmentOwner>((ref, owner) async {
  try {
    final rows = await ref
        .watch(supabaseClientProvider)
        .from('attachments')
        .select()
        .eq('owner_table', owner.table)
        .eq('owner_id', owner.id)
        .order('created_at');
    return rows.map(Attachment.fromJson).toList();
  } catch (e) {
    throw AppFailure.from(e);
  }
});

/// Short-lived signed URL for a private object (1 hour).
final signedUrlProvider = FutureProvider.autoDispose.family<String, String>((ref, path) async {
  try {
    return await ref.watch(supabaseClientProvider).storage.from('attachments').createSignedUrl(path, 3600);
  } catch (e) {
    throw AppFailure.from(e);
  }
});

/// Uploads not yet synced for an owner (shown as "N waiting to upload").
final pendingUploadsProvider = Provider.family<int, AttachmentOwner>((ref, owner) {
  final prefix = '${owner.table}/${owner.id}/';
  return ref
      .watch(outboxProvider.select((s) => s.ops))
      .where((o) => o.kind == OutboxKind.upload && o.name.startsWith(prefix) && !o.failed)
      .length;
});

final attachmentServiceProvider = Provider<AttachmentService>(AttachmentService.new);

class AttachmentService {
  AttachmentService(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  /// Photos are downscaled by the picker (≈1600px, JPEG q70 → ~200–400 KB)
  /// to fit the free storage tier.
  static Future<XFile?> pickPhoto(ImageSource source) => ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 70,
        requestFullMetadata: false,
      );

  /// Attaches [file] to the record. On phones it is queued (works offline,
  /// survives restarts); on the web it uploads immediately. Returns true if
  /// it reached the server now.
  Future<bool> attach({
    required AttachmentOwner owner,
    required XFile file,
    CapturedLocation? location,
    String mimeType = 'image/jpeg',
    String kind = 'photo',
  }) async {
    final id = _uuid.v4();
    final ext = mimeType == 'application/pdf' ? 'pdf' : 'jpg';
    final storagePath = '${owner.table}/${owner.id}/$id.$ext';
    final size = await file.length();
    final row = {
      'id': id,
      'owner_table': owner.table,
      'owner_id': owner.id,
      'kind': kind,
      'storage_path': storagePath,
      'file_name': file.name,
      'mime_type': mimeType,
      'size_bytes': size,
      'captured_at': DateTime.now().toUtc().toIso8601String(),
      'lat': location?.lat,
      'lng': location?.lng,
    };

    if (kIsWeb) {
      final client = _ref.read(supabaseClientProvider);
      try {
        await client.from('attachments').insert(row);
        await client.storage.from('attachments').uploadBinary(storagePath, await file.readAsBytes(),
            fileOptions: FileOptions(contentType: mimeType));
      } catch (e) {
        throw AppFailure.from(e);
      }
      _ref.invalidate(attachmentsProvider(owner));
      return true;
    }

    final localPath = await persistForUpload(file.path, '$id.$ext');
    final outbox = _ref.read(outboxProvider.notifier);
    final now = DateTime.now().toUtc();
    await outbox.enqueue(OutboxOp(
      id: 'att-$id',
      kind: OutboxKind.insert,
      name: 'attachments',
      label: 'Photo for ${owner.table}',
      createdAt: now,
      payload: row,
    ));
    await outbox.enqueue(OutboxOp(
      id: 'upl-$id',
      kind: OutboxKind.upload,
      name: storagePath,
      label: 'Photo upload',
      createdAt: now,
      filePath: localPath,
      mimeType: mimeType,
    ));
    await outbox.process();
    _ref.invalidate(attachmentsProvider(owner));
    return !_ref.read(outboxProvider).ops.any((o) => o.id == 'upl-$id');
  }
}
