import '../../core/design/design.dart';
import '../../core/l10n/l10n.dart';

String poleTypeLabel(AppLocalizations l, String t) => switch (t) {
      'psc' => l.poleTypePsc,
      'rcc' => l.poleTypeRcc,
      'steel_tubular' => l.poleTypeSteel,
      'rail' => l.poleTypeRail,
      'wooden' => l.poleTypeWooden,
      _ => l.poleTypeOther,
    };

String poleConditionLabel(AppLocalizations l, String c) => switch (c) {
      'leaning' => l.poleCondLeaning,
      'damaged' => l.poleCondDamaged,
      'replaced' => l.poleCondReplaced,
      _ => l.poleCondGood,
    };

StatusChip poleConditionChip(AppLocalizations l, String c) => StatusChip(
      label: poleConditionLabel(l, c),
      tone: switch (c) {
        'leaning' => StatusTone.warning,
        'damaged' => StatusTone.danger,
        'replaced' => StatusTone.info,
        _ => StatusTone.success,
      },
      dense: true,
    );

String assetCategoryLabel(AppLocalizations l, String c) => switch (c) {
      'transformer' => l.assetCatTransformer,
      'pole' => l.assetCatPole,
      'conductor' => l.assetCatConductor,
      'meter' => l.assetCatMeter,
      'tool' => l.assetCatTool,
      'vehicle' => l.assetCatVehicle,
      _ => l.assetCatOther,
    };

String assetConditionLabel(AppLocalizations l, String c) => switch (c) {
      'new' => l.assetCondNew,
      'fair' => l.assetCondFair,
      'poor' => l.assetCondPoor,
      'unserviceable' => l.assetCondUnserviceable,
      _ => l.assetCondGood,
    };

String assetStatusLabel(AppLocalizations l, String s) => switch (s) {
      'deployed' => l.assetStatusDeployed,
      'under_repair' => l.assetStatusUnderRepair,
      'scrapped' => l.assetStatusScrapped,
      'lost' => l.assetStatusLost,
      _ => l.assetStatusInStore,
    };

StatusChip assetStatusChip(AppLocalizations l, String s) => StatusChip(
      label: assetStatusLabel(l, s),
      tone: switch (s) {
        'deployed' => StatusTone.success,
        'under_repair' => StatusTone.warning,
        'scrapped' || 'lost' => StatusTone.danger,
        _ => StatusTone.neutral,
      },
      dense: true,
    );

String assetEventLabel(AppLocalizations l, String e) => switch (e) {
      'created' => l.assetEvCreated,
      'assigned' => l.assetEvAssigned,
      'moved' => l.assetEvMoved,
      'inspected' => l.assetEvInspected,
      'repaired' => l.assetEvRepaired,
      'scrapped' => l.assetEvScrapped,
      _ => l.assetEvStatusChanged,
    };
