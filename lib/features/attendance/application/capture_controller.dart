import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/location/location_service.dart';
import '../../../core/outbox/outbox.dart';
import '../data/attendance_repository.dart';

enum CaptureKind { checkIn, checkOut }

enum CaptureOutcome {
  /// Accepted by the server.
  synced,

  /// Saved on the phone; uploads automatically when back online.
  queued,

  /// The server refused it (e.g. already checked in); [CaptureResult.message]
  /// says why. Nothing is left in the queue.
  rejected,
}

class CaptureResult {
  const CaptureResult(this.outcome, {this.message});
  final CaptureOutcome outcome;
  final String? message;
}

/// A check-in/out captured on this phone that hasn't reached the server.
class PendingCapture {
  const PendingCapture(this.kind, this.capturedAt);
  final CaptureKind kind;
  final DateTime capturedAt;
}

final captureControllerProvider = Provider<CaptureController>(CaptureController.new);

/// Pending (unsynced) captures for today, newest last.
final pendingCapturesProvider = Provider<List<PendingCapture>>((ref) {
  final ops = ref.watch(outboxProvider.select((s) => s.ops));
  return [
    for (final op in ops)
      if (!op.failed && (op.name == 'check_in' || op.name == 'check_out'))
        PendingCapture(
          op.name == 'check_in' ? CaptureKind.checkIn : CaptureKind.checkOut,
          DateTime.parse(op.payload['p_captured_at'] as String).toLocal(),
        ),
  ];
});

class CaptureController {
  CaptureController(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  /// Records a check-in/out at this moment. [location] may be null only when
  /// the user explicitly chose to continue without GPS (flagged for review).
  Future<CaptureResult> capture(
    CaptureKind kind, {
    CapturedLocation? location,
    String? worksheetId,
    DateTime? now,
  }) async {
    final capturedAt = (now ?? DateTime.now()).toUtc();
    final requestId = _uuid.v4();
    final rpc = kind == CaptureKind.checkIn ? 'check_in' : 'check_out';
    final op = OutboxOp(
      id: requestId,
      kind: OutboxKind.rpc,
      name: rpc,
      label: '${kind == CaptureKind.checkIn ? 'Check-in' : 'Check-out'} '
          '${capturedAt.toLocal().hour.toString().padLeft(2, '0')}:'
          '${capturedAt.toLocal().minute.toString().padLeft(2, '0')}',
      createdAt: capturedAt,
      payload: {
        'p_request_id': requestId,
        'p_captured_at': capturedAt.toIso8601String(),
        'p_lat': location?.lat,
        'p_lng': location?.lng,
        'p_accuracy_m': location?.accuracyM,
        'p_is_mocked': location?.isMocked ?? false,
        if (kind == CaptureKind.checkIn) 'p_worksheet_id': worksheetId,
      },
    );

    final outbox = _ref.read(outboxProvider.notifier);
    await outbox.enqueue(op);
    await outbox.process();

    final after = _ref.read(outboxProvider).ops.where((o) => o.id == requestId).firstOrNull;
    _ref.invalidate(myTodayProvider);
    if (after == null) return const CaptureResult(CaptureOutcome.synced);
    if (after.failed) {
      // A rejected capture can't succeed on retry; surface it and clear it.
      await outbox.discard(requestId);
      return CaptureResult(CaptureOutcome.rejected, message: after.lastError);
    }
    return const CaptureResult(CaptureOutcome.queued);
  }
}
