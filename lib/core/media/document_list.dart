import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design/design.dart';
import '../errors/app_failure.dart';
import '../format/formatters.dart';
import '../l10n/l10n.dart';
import '../ui/dialogs.dart';
import 'attachments.dart';

/// PDF documents attached to a record (work orders, bills, letters...).
class DocumentList extends ConsumerStatefulWidget {
  const DocumentList({super.key, required this.owner, this.canAdd = true});

  final AttachmentOwner owner;
  final bool canAdd;

  @override
  ConsumerState<DocumentList> createState() => _DocumentListState();
}

class _DocumentListState extends ConsumerState<DocumentList> {
  bool _busy = false;

  Future<void> _attach() async {
    final l10n = context.l10n;
    final file = await openFile(acceptedTypeGroups: const [
      XTypeGroup(label: 'PDF', extensions: ['pdf'], mimeTypes: ['application/pdf']),
    ]);
    if (file == null) return;
    if (await file.length() > 10 * 1024 * 1024) {
      if (mounted) showSnack(context, l10n.comPdfTooLarge);
      return;
    }
    setState(() => _busy = true);
    try {
      final synced = await ref
          .read(attachmentServiceProvider)
          .attach(owner: widget.owner, file: file, mimeType: 'application/pdf', kind: 'document');
      if (!synced && mounted) showSnack(context, l10n.wsPhotoQueued);
    } catch (e) {
      if (mounted) showSnack(context, failureMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(Attachment a) async {
    try {
      final url = await ref.read(signedUrlProvider(a.storagePath).future);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) showSnack(context, failureMessage(context.l10n, AppFailure.from(e)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final docs = (ref.watch(attachmentsProvider(widget.owner)).value ?? const <Attachment>[])
        .where((a) => !a.isImage)
        .toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(
        l10n.comDocuments,
        action: widget.canAdd
            ? AppButton.tertiary(label: l10n.comAttachPdf, icon: Icons.attach_file_rounded, loading: _busy, onPressed: _attach)
            : null,
      ),
      if (docs.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(l10n.comNoDocuments, style: AppTypography.caption),
        )
      else
        for (final d in docs)
          AppListRow(
            leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.danger),
            title: d.fileName ?? 'document.pdf',
            subtitle: Fmt.dateTime(d.createdAt),
            onTap: () => _open(d),
          ),
    ]);
  }
}
