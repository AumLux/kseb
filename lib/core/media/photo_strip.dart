import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../design/design.dart';
import '../errors/app_failure.dart';
import '../l10n/l10n.dart';
import '../location/location_service.dart';
import '../ui/dialogs.dart';
import 'attachments.dart';

/// Horizontal strip of a record's photos with an "Add photo" tile.
/// Photos still waiting to upload are counted, not hidden.
class PhotoStrip extends ConsumerStatefulWidget {
  const PhotoStrip({super.key, required this.owner, this.canAdd = true, this.title});

  final AttachmentOwner owner;
  final bool canAdd;
  final String? title;

  @override
  ConsumerState<PhotoStrip> createState() => _PhotoStripState();
}

class _PhotoStripState extends ConsumerState<PhotoStrip> {
  bool _busy = false;

  Future<void> _add() async {
    final l10n = context.l10n;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded),
            title: Text(l10n.wsCamera),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: Text(l10n.wsGallery),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;
    final file = await AttachmentService.pickPhoto(source);
    if (file == null) return;
    setState(() => _busy = true);
    try {
      CapturedLocation? loc;
      if (source == ImageSource.camera) {
        try {
          loc = await ref.read(locationServiceProvider).current();
        } on AppFailure {
          loc = null; // A photo without GPS is still useful.
        }
      }
      final synced = await ref.read(attachmentServiceProvider).attach(owner: widget.owner, file: file, location: loc);
      if (!synced && mounted) showSnack(context, l10n.wsPhotoQueued);
    } catch (e) {
      if (mounted) showSnack(context, failureMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final photos = ref.watch(attachmentsProvider(widget.owner));
    final pending = ref.watch(pendingUploadsProvider(widget.owner));
    final images = (photos.value ?? const <Attachment>[]).where((a) => a.isImage).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          widget.title ?? l10n.wsPhotos,
          action: pending > 0 ? SyncBadge(pending: pending) : null,
        ),
        SizedBox(
          height: 112,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            children: [
              if (widget.canAdd)
                _Tile(
                  onTap: _busy ? null : _add,
                  child: _busy
                      ? const Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.add_a_photo_rounded, color: AppColors.primaryInk),
                          const SizedBox(height: AppSpacing.xs),
                          Text(l10n.wsAddPhoto, style: AppTypography.caption, textAlign: TextAlign.center),
                        ]),
                ),
              for (final a in images) _Thumb(attachment: a),
              if (images.isEmpty && !widget.canAdd)
                Center(child: Text(l10n.wsPhotosEmpty, style: AppTypography.caption)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: SizedBox(
          width: 112,
          child: AppCard(padding: EdgeInsets.zero, onTap: onTap, child: child),
        ),
      );
}

class _Thumb extends ConsumerWidget {
  const _Thumb({required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(signedUrlProvider(attachment.storagePath)).value;
    return _Tile(
      onTap: url == null
          ? null
          : () => showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  insetPadding: const EdgeInsets.all(AppSpacing.lg),
                  child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
                ),
              ),
      child: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: url == null
            ? const ColoredBox(color: AppColors.canvasSunken)
            : Image.network(
                url,
                fit: BoxFit.cover,
                semanticLabel: attachment.fileName,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: AppColors.inkMute),
              ),
      ),
    );
  }
}
