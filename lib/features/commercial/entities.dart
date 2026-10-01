import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';

/// How a field is edited, validated and displayed.
enum FieldKind { text, multiline, money, date, datetime, month, choice, ref, phone, gstin }

typedef L10nText = String Function(AppLocalizations l);

/// One column of a commercial register. Screens, validation and exports are
/// all generated from these definitions, so the six registers behave the
/// same way.
class FieldDef {
  const FieldDef(
    this.key,
    this.label,
    this.kind, {
    this.required = false,
    this.options = const [],
    this.optionLabel,
    this.refEntity,
    this.defaultValue,
  });

  final String key;
  final L10nText label;
  final FieldKind kind;
  final bool required;

  /// For [FieldKind.choice]: stored values.
  final List<String> options;
  final String Function(AppLocalizations l, String value)? optionLabel;

  /// For [FieldKind.ref]: the [EntityDef.key] being referenced.
  final String? refEntity;
  final Object? defaultValue;

  String labelFor(AppLocalizations l, String value) => optionLabel?.call(l, value) ?? value;
}

class EntityDef {
  const EntityDef({
    required this.key,
    required this.table,
    required this.title,
    required this.icon,
    required this.fields,
    required this.primary,
    required this.secondary,
    required this.orderBy,
    required this.searchColumns,
    this.statusField,
    this.ascending = false,
  });

  /// Route segment, e.g. `tenders` → /more/commercial/tenders.
  final String key;
  final String table;
  final L10nText title;
  final IconData icon;
  final List<FieldDef> fields;

  /// Columns used for the list row title / subtitle and for references.
  final List<String> primary;
  final List<String> secondary;
  final String orderBy;
  final bool ascending;
  final List<String> searchColumns;
  final String? statusField;

  FieldDef field(String key) => fields.firstWhere((f) => f.key == key);
  FieldDef? get status => statusField == null ? null : field(statusField!);

  String display(Map<String, dynamic> row) =>
      primary.map((c) => row[c]?.toString() ?? '').where((s) => s.isNotEmpty).join(' · ');
}

String _opt(AppLocalizations l, String v) => switch (v) {
      // tenders
      'draft' => l.optTenderDraft,
      'submitted' => l.optTenderSubmitted,
      'opened' => l.optTenderOpened,
      'awarded' => l.optTenderAwarded,
      'lost' => l.optTenderLost,
      'cancelled' => l.optTenderCancelled,
      // deposits
      'emd' => l.optDepEmd,
      'sd' => l.optDepSd,
      'bg' => l.optDepBg,
      'retention' => l.optDepRetention,
      'held' => l.optDepHeld,
      'refund_requested' => l.optDepRefundRequested,
      'released' => l.optDepReleased,
      'forfeited' => l.optDepForfeited,
      'dd' => l.optModeDd,
      'online' => l.optModeOnline,
      'fdr' => l.optModeFdr,
      'cash' => l.optModeCash,
      // work orders
      'in_progress' => l.optWoInProgress,
      'completed' => l.optWoCompleted,
      'closed' => l.optWoClosed,
      'terminated' => l.optWoTerminated,
      // bills
      'ra' => l.optBillRa,
      'final' => l.optBillFinal,
      'advance' => l.optBillAdvance,
      'passed' => l.optBillPassed,
      'partially_paid' => l.optBillPartiallyPaid,
      'paid' => l.optBillPaid,
      'rejected' => l.optBillRejected,
      // correspondence
      'in' => l.optDirIn,
      'out' => l.optDirOut,
      'letter' => l.optDocLetter,
      'notice' => l.optDocNotice,
      'circular' => l.optDocCircular,
      'work_order' => l.optDocWorkOrder,
      'other' => l.optDocOther,
      _ => v,
    };

/// Context-free labels where the same stored value means different things.
String _paymentMode(AppLocalizations l, String v) => switch (v) {
      'bg' => l.optModeBg,
      'other' => l.optModeOther,
      _ => _opt(l, v),
    };

String _billStatus(AppLocalizations l, String v) => v == 'submitted' ? l.optBillSubmitted : _opt(l, v);
String _billType(AppLocalizations l, String v) => v == 'other' ? l.optBillOther : _opt(l, v);
String _woStatus(AppLocalizations l, String v) => v == 'awarded' ? l.optWoAwarded : _opt(l, v);

const tenderTypes = ['Open Tender', 'Limited Tender', 'E-Tender', 'Work Order', 'Estimate'];
const workCategories = ['Electrical', 'Civil', 'Electrical + Civil', 'Maintenance', 'Materials'];

final tendersEntity = EntityDef(
  key: 'tenders',
  table: 'tenders',
  title: (l) => l.entTenders,
  icon: Icons.gavel_rounded,
  primary: ['reference', 'title'],
  secondary: ['submission_deadline', 'estimate_amount'],
  orderBy: 'created_at',
  searchColumns: ['reference', 'title', 'location'],
  statusField: 'status',
  fields: [
    FieldDef('reference', (l) => l.fReference, FieldKind.text, required: true),
    FieldDef('title', (l) => l.fTitle, FieldKind.text, required: true),
    FieldDef('tender_type', (l) => l.fTenderType, FieldKind.choice, options: tenderTypes),
    FieldDef('work_category', (l) => l.fWorkCategory, FieldKind.choice, options: workCategories),
    FieldDef('department', (l) => l.fDepartment, FieldKind.text, defaultValue: 'KSEB'),
    FieldDef('section_id', (l) => l.fSection, FieldKind.ref, refEntity: 'sections'),
    FieldDef('location', (l) => l.fLocation, FieldKind.text),
    FieldDef('notice_date', (l) => l.fNoticeDate, FieldKind.date),
    FieldDef('submission_deadline', (l) => l.fSubmissionDeadline, FieldKind.datetime),
    FieldDef('opening_date', (l) => l.fOpeningDate, FieldKind.date),
    FieldDef('work_start_date', (l) => l.fWorkStartDate, FieldKind.date),
    FieldDef('estimate_amount', (l) => l.fEstimate, FieldKind.money),
    FieldDef('emd_amount', (l) => l.fEmd, FieldKind.money),
    FieldDef('security_deposit', (l) => l.fSecurityDeposit, FieldKind.money),
    FieldDef('quoted_amount', (l) => l.fQuoted, FieldKind.money),
    FieldDef('contact_person', (l) => l.fContactPerson, FieldKind.text),
    FieldDef('contact_phone', (l) => l.fContactPhone, FieldKind.phone),
    FieldDef('status', (l) => l.fStatus, FieldKind.choice,
        required: true,
        options: const ['draft', 'submitted', 'opened', 'awarded', 'lost', 'cancelled'],
        optionLabel: _opt,
        defaultValue: 'draft'),
    FieldDef('remarks', (l) => l.fRemarks, FieldKind.multiline),
  ],
);

final depositsEntity = EntityDef(
  key: 'deposits',
  table: 'deposits',
  title: (l) => l.entDeposits,
  icon: Icons.account_balance_rounded,
  primary: ['instrument_no', 'bank_name'],
  secondary: ['validity_date', 'amount'],
  orderBy: 'validity_date',
  ascending: true,
  searchColumns: ['instrument_no', 'bank_name', 'remarks'],
  statusField: 'status',
  fields: [
    FieldDef('kind', (l) => l.fKind, FieldKind.choice,
        required: true, options: const ['emd', 'sd', 'bg', 'retention'], optionLabel: _opt, defaultValue: 'emd'),
    FieldDef('tender_id', (l) => l.fTender, FieldKind.ref, refEntity: 'tenders'),
    FieldDef('work_order_id', (l) => l.fWorkOrder, FieldKind.ref, refEntity: 'work_orders'),
    FieldDef('amount', (l) => l.fAmount, FieldKind.money, required: true),
    FieldDef('payment_mode', (l) => l.fPaymentMode, FieldKind.choice,
        required: true, options: const ['dd', 'bg', 'online', 'fdr', 'cash', 'other'], optionLabel: _paymentMode, defaultValue: 'online'),
    FieldDef('instrument_no', (l) => l.fInstrumentNo, FieldKind.text),
    FieldDef('bank_name', (l) => l.fBank, FieldKind.text),
    FieldDef('deposit_date', (l) => l.fDepositDate, FieldKind.date, required: true),
    FieldDef('validity_date', (l) => l.fValidityDate, FieldKind.date),
    FieldDef('status', (l) => l.fStatus, FieldKind.choice,
        required: true, options: const ['held', 'refund_requested', 'released', 'forfeited'], optionLabel: _opt, defaultValue: 'held'),
    FieldDef('released_on', (l) => l.fReleasedOn, FieldKind.date),
    FieldDef('remarks', (l) => l.fRemarks, FieldKind.multiline),
  ],
);

final workOrdersEntity = EntityDef(
  key: 'work-orders',
  table: 'work_orders',
  title: (l) => l.entWorkOrders,
  icon: Icons.description_rounded,
  primary: ['wo_number', 'title'],
  secondary: ['issue_date', 'awarded_amount'],
  orderBy: 'issue_date',
  searchColumns: ['wo_number', 'agreement_no', 'title'],
  statusField: 'status',
  fields: [
    FieldDef('wo_number', (l) => l.fWoNumber, FieldKind.text, required: true),
    FieldDef('agreement_no', (l) => l.fAgreementNo, FieldKind.text),
    FieldDef('tender_id', (l) => l.fTender, FieldKind.ref, refEntity: 'tenders'),
    FieldDef('title', (l) => l.fTitle, FieldKind.text, required: true),
    FieldDef('section_id', (l) => l.fSection, FieldKind.ref, refEntity: 'sections'),
    FieldDef('awarded_amount', (l) => l.fAwardedAmount, FieldKind.money, required: true),
    FieldDef('issue_date', (l) => l.fIssueDate, FieldKind.date, required: true),
    FieldDef('due_date', (l) => l.fDueDate, FieldKind.date),
    FieldDef('status', (l) => l.fStatus, FieldKind.choice,
        required: true, options: const ['awarded', 'in_progress', 'completed', 'closed', 'terminated'], optionLabel: _woStatus, defaultValue: 'awarded'),
    FieldDef('remarks', (l) => l.fRemarks, FieldKind.multiline),
  ],
);

final billsEntity = EntityDef(
  key: 'bills',
  table: 'bills',
  title: (l) => l.entBills,
  icon: Icons.request_quote_rounded,
  primary: ['invoice_no'],
  secondary: ['invoice_date', 'amount'],
  orderBy: 'invoice_date',
  searchColumns: ['invoice_no', 'remarks'],
  statusField: 'status',
  fields: [
    FieldDef('invoice_no', (l) => l.fInvoiceNo, FieldKind.text, required: true),
    FieldDef('bill_type', (l) => l.fBillType, FieldKind.choice,
        required: true, options: const ['ra', 'final', 'advance', 'other'], optionLabel: _billType, defaultValue: 'ra'),
    FieldDef('work_order_id', (l) => l.fWorkOrder, FieldKind.ref, refEntity: 'work_orders', required: true),
    FieldDef('invoice_date', (l) => l.fInvoiceDate, FieldKind.date, required: true),
    FieldDef('amount', (l) => l.fAmount, FieldKind.money, required: true),
    FieldDef('tax_amount', (l) => l.fTaxAmount, FieldKind.money, defaultValue: 0),
    FieldDef('status', (l) => l.fStatus, FieldKind.choice,
        required: true,
        options: const ['submitted', 'passed', 'partially_paid', 'paid', 'rejected'],
        optionLabel: _billStatus,
        defaultValue: 'submitted'),
    FieldDef('passed_amount', (l) => l.fPassedAmount, FieldKind.money),
    FieldDef('paid_amount', (l) => l.fPaidAmount, FieldKind.money, defaultValue: 0),
    FieldDef('paid_on', (l) => l.fPaidOn, FieldKind.date),
    FieldDef('remarks', (l) => l.fRemarks, FieldKind.multiline),
  ],
);

final lettersEntity = EntityDef(
  key: 'letters',
  table: 'correspondence',
  title: (l) => l.entLetters,
  icon: Icons.mark_email_read_rounded,
  primary: ['ref_no', 'subject'],
  secondary: ['doc_date', 'party'],
  orderBy: 'doc_date',
  searchColumns: ['ref_no', 'subject', 'party'],
  fields: [
    FieldDef('ref_no', (l) => l.fRefNo, FieldKind.text, required: true),
    FieldDef('direction', (l) => l.fDirection, FieldKind.choice,
        required: true, options: const ['in', 'out'], optionLabel: _opt, defaultValue: 'in'),
    FieldDef('doc_type', (l) => l.fDocType, FieldKind.choice,
        required: true, options: const ['letter', 'notice', 'circular', 'work_order', 'other'], optionLabel: _opt, defaultValue: 'letter'),
    FieldDef('party', (l) => l.fParty, FieldKind.text, required: true),
    FieldDef('subject', (l) => l.fSubject, FieldKind.text, required: true),
    FieldDef('doc_date', (l) => l.fDocDate, FieldKind.date, required: true),
    FieldDef('tender_id', (l) => l.fTender, FieldKind.ref, refEntity: 'tenders'),
    FieldDef('work_order_id', (l) => l.fWorkOrder, FieldKind.ref, refEntity: 'work_orders'),
    FieldDef('remarks', (l) => l.fRemarks, FieldKind.multiline),
  ],
);

final gstEntity = EntityDef(
  key: 'gst',
  table: 'gst_returns',
  title: (l) => l.entGst,
  icon: Icons.receipt_long_rounded,
  primary: ['return_type', 'gstin'],
  secondary: ['period', 'taxable_value'],
  orderBy: 'period',
  searchColumns: ['gstin', 'legal_name', 'arn'],
  fields: [
    FieldDef('gstin', (l) => l.fGstin, FieldKind.gstin, required: true),
    FieldDef('legal_name', (l) => l.fLegalName, FieldKind.text, required: true),
    FieldDef('return_type', (l) => l.fReturnType, FieldKind.choice,
        required: true, options: const ['GSTR-1', 'GSTR-3B', 'GSTR-9', 'other'], defaultValue: 'GSTR-3B'),
    FieldDef('period', (l) => l.fPeriod, FieldKind.month, required: true),
    FieldDef('taxable_value', (l) => l.fTaxable, FieldKind.money, defaultValue: 0),
    FieldDef('cgst', (l) => l.fCgst, FieldKind.money, defaultValue: 0),
    FieldDef('sgst', (l) => l.fSgst, FieldKind.money, defaultValue: 0),
    FieldDef('igst', (l) => l.fIgst, FieldKind.money, defaultValue: 0),
    FieldDef('filed_on', (l) => l.fFiledOn, FieldKind.date),
    FieldDef('arn', (l) => l.fArn, FieldKind.text),
    FieldDef('remarks', (l) => l.fRemarks, FieldKind.multiline),
  ],
);

final commercialEntities = [tendersEntity, depositsEntity, workOrdersEntity, billsEntity, lettersEntity, gstEntity];

EntityDef entityByKey(String key) => commercialEntities.firstWhere((e) => e.key == key);

/// Entity definition for a referenced table (sections are org data).
String refTable(String refEntity) => refEntity == 'sections'
    ? 'sections'
    : refEntity == 'tenders'
        ? 'tenders'
        : 'work_orders';

/// Columns to show when listing a referenced record in a picker.
List<String> refDisplayColumns(String refEntity) => switch (refEntity) {
      'sections' => const ['name'],
      'tenders' => const ['reference', 'title'],
      _ => const ['wo_number', 'title'],
    };

/// Back-references shown on a record's detail page.
class LinkDef {
  const LinkDef(this.entity, this.column);
  final EntityDef entity;
  final String column;
}

List<LinkDef> linksFor(EntityDef e) => switch (e.key) {
      'tenders' => [LinkDef(depositsEntity, 'tender_id'), LinkDef(workOrdersEntity, 'tender_id'), LinkDef(lettersEntity, 'tender_id')],
      'work-orders' => [LinkDef(billsEntity, 'work_order_id'), LinkDef(depositsEntity, 'work_order_id'), LinkDef(lettersEntity, 'work_order_id')],
      _ => const [],
    };
