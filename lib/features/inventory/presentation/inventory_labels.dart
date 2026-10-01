import '../../../core/design/design.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/l10n.dart';
import '../../leave/leave.dart' show requestStatusLabel;
import '../data/inventory_repository.dart';

String requestTypeLabel(AppLocalizations l10n, MaterialRequestType t) => switch (t) {
      MaterialRequestType.issue => l10n.invTypeIssue,
      MaterialRequestType.ret => l10n.invTypeReturn,
      MaterialRequestType.receipt => l10n.invTypeReceipt,
    };

String priorityLabel(AppLocalizations l10n, Priority p) => switch (p) {
      Priority.low => l10n.invPriorityLow,
      Priority.medium => l10n.invPriorityMedium,
      Priority.high => l10n.invPriorityHigh,
      Priority.critical => l10n.invPriorityCritical,
    };

String txnLabel(AppLocalizations l10n, String t) => switch (t) {
      'receipt' => l10n.invTxnReceipt,
      'issue' => l10n.invTxnIssue,
      'return' => l10n.invTxnReturn,
      'adjustment' => l10n.invTxnAdjustment,
      'transfer_in' => l10n.invTxnTransferIn,
      'transfer_out' => l10n.invTxnTransferOut,
      'scrap' => l10n.invTxnScrap,
      _ => t,
    };

StatusChip requestChip(AppLocalizations l10n, String status) =>
    StatusChip.fromDomain(status, label: requestStatusLabel(l10n, status));

/// `+12.5 m` / `-3 nos` for ledger rows.
String signedQty(num delta, String unit) => '${delta > 0 ? '+' : ''}${Fmt.qty(delta, unit: unit)}';
