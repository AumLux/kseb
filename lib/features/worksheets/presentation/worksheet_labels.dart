import '../../../core/design/design.dart';
import '../../../core/l10n/l10n.dart';
import '../data/worksheet_repository.dart';

String workTypeLabel(AppLocalizations l10n, WorkType t) => switch (t) {
      WorkType.project => l10n.wsTypeProject,
      WorkType.maintenance => l10n.wsTypeMaintenance,
      WorkType.calamity => l10n.wsTypeCalamity,
    };

String worksheetStatusLabel(AppLocalizations l10n, WorksheetStatus s) => switch (s) {
      WorksheetStatus.draft => l10n.wsStatusDraft,
      WorksheetStatus.submitted => l10n.wsStatusSubmitted,
      WorksheetStatus.approved => l10n.wsStatusApproved,
      WorksheetStatus.rejected => l10n.wsStatusRejected,
      WorksheetStatus.inProgress => l10n.wsStatusInProgress,
      WorksheetStatus.completed => l10n.wsStatusCompleted,
      WorksheetStatus.cancelled => l10n.wsStatusCancelled,
    };

StatusChip worksheetChip(AppLocalizations l10n, WorksheetStatus s) =>
    StatusChip.fromDomain(s.db, label: worksheetStatusLabel(l10n, s));

String ppeLabel(AppLocalizations l10n, String key) => switch (key) {
      'helmet' => l10n.ppeHelmet,
      'gloves' => l10n.ppeGloves,
      'safety_belt' => l10n.ppeSafetyBelt,
      'boots' => l10n.ppeBoots,
      'insulated_tools' => l10n.ppeInsulatedTools,
      'reflective_vest' => l10n.ppeReflectiveVest,
      _ => key,
    };

String severityLabel(AppLocalizations l10n, IncidentSeverity s) => switch (s) {
      IncidentSeverity.nearMiss => l10n.incNearMiss,
      IncidentSeverity.minor => l10n.incMinor,
      IncidentSeverity.major => l10n.incMajor,
      IncidentSeverity.fatal => l10n.incFatal,
    };
