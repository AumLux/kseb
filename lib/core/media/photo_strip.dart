import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../design/design.dart';
import '../errors/app_failure.dart';
import '../format/formatters.dart';
import '../l10n/l10n.dart';
import '../location/location_rationale.dart';
import '../location/location_service.dart';
import '../maps/app_map.dart';
import '../ui/dialogs.dart';
import '../ui/maps.dart';
import '../ui/sheets.dart';
import 'attachments.dart';
import 'local_image.dart';

/// A record's photos: an "Add photo" tile, photos still uploading (shown from
/// the phone, never hidden), and uploaded photos with their GPS tag. Tapping
/// a photo opens a full-screen viewer with time, coordinates and a map.
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
    final source = await showAppSheet<ImageSource>(
      context,
      builder: (context) => SheetScaffold(
        title: l10n.wsAddPhoto,
        children: [
          AppListRow(
            leading: const IconTile(Icons.photo_camera_rounded),
            title: l10n.wsCamera,
            subtitle: l10n.photoGpsTagged,
            showDivider: false,
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          AppListRow(
            leading: const IconTile(Icons.photo_library_rounded, color: AppColors.inkSecondary),
            title: l10n.wsGallery,
            showDivider: false,
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
    if (source == null || !mounted) return;

    // Camera photos are GPS-tagged. Settle the permission *before* the camera
    // opens, then let the GPS warm up while the photo is being taken.
    Future<CapturedLocation?>? fix;
    if (source == ImageSource.camera) {
      final service = ref.read(locationServiceProvider);
      if (await explainLocationIfNeeded(context, ref) && await service.requestPermission()) {
        fix = service.current().then<CapturedLocation?>((l) => l).catchError((Object _) => null);
      }
    }
    if (!mounted) return;
    final service = ref.read(attachmentServiceProvider);
    final file = await service.pickPhoto(source, widget.owner);
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final loc = await fix?.timeout(const Duration(seconds: 12), onTimeout: () => null);
      final synced = await service.attach(owner: widget.owner, file: file, location: loc);
      if (!synced && mounted) showSnack(context, l10n.wsPhotoQueued);
    } on AppFailure catch (f) {
      if (mounted) showSnack(context, failureMessage(l10n, f));
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
    final pending = ref.watch(pendingPhotoPathsProvider(widget.owner));
    final images = (photos.value ?? const <Attachment>[]).where((a) => a.isImage).toList();
    final count = images.length + pending.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          count == 0 ? (widget.title ?? l10n.wsPhotos) : '${widget.title ?? l10n.wsPhotos} · $count',
          action: pending.isNotEmpty ? SyncBadge(pending: pending.length) : null,
        ),
        SizedBox(
          height: _Tile.size,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            children: [
              if (widget.canAdd) _AddTile(busy: _busy, onTap: _busy ? null : _add),
              for (final path in pending.reversed) _PendingThumb(path: path),
              for (final (i, a) in images.indexed) _Thumb(attachments: images, index: i, key: ValueKey(a.id)),
              if (count == 0 && !widget.canAdd)
                Center(child: Text(l10n.wsPhotosEmpty, style: AppTypography.caption)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.child, this.onTap, this.semanticLabel});

  static const double size = 116;

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: Semantics(
          button: onTap != null,
          label: semanticLabel,
          child: Pressable(
            onTap: onTap,
            borderRadius: AppRadius.lgAll,
            child: ClipRRect(
              borderRadius: AppRadius.lgAll,
              child: SizedBox.square(dimension: size, child: child),
            ),
          ),
        ),
      );
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.busy, this.onTap});

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => _Tile(
        onTap: onTap,
        semanticLabel: context.l10n.wsAddPhoto,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: busy
              ? const Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.4)))
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.add_a_photo_rounded, color: AppColors.primaryDeep, size: 28),
                  const SizedBox(height: AppSpacing.sm),
                  Text(context.l10n.wsAddPhoto,
                      style: AppTypography.label.copyWith(color: AppColors.primaryDeep, fontSize: 12.5),
                      textAlign: TextAlign.center),
                ]),
        ),
      );
}

/// Thumbnail decode width: the tile's size at the screen's pixel density.
int _thumbPx(BuildContext context) => (_Tile.size * MediaQuery.devicePixelRatioOf(context)).round();

class _PendingThumb extends StatelessWidget {
  const _PendingThumb({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) => _Tile(
        child: Stack(fit: StackFit.expand, children: [
          localImage(path, cacheWidth: _thumbPx(context)),
          const ColoredBox(color: Color(0x660D253D)),
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_upload_rounded, color: Colors.white),
              const SizedBox(height: AppSpacing.xs),
              Text(context.l10n.photoWaiting, style: AppTypography.caption.copyWith(color: Colors.white)),
            ]),
          ),
        ]),
      );
}

class _Thumb extends ConsumerWidget {
  const _Thumb({super.key, required this.attachments, required this.index});

  final List<Attachment> attachments;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = attachments[index];
    final url = ref.watch(signedUrlProvider(a.storagePath)).value;
    return _Tile(
      semanticLabel: a.fileName,
      onTap: () => Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(
        builder: (_) => PhotoViewerPage(attachments: attachments, initialIndex: index),
      )),
      child: Stack(fit: StackFit.expand, children: [
        if (url == null)
          const Skeleton(child: ColoredBox(color: AppColors.canvasSunken))
        else
          Image.network(
            url,
            fit: BoxFit.cover,
            cacheWidth: _thumbPx(context), // decode small: full-size decodes exhaust memory
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: AppColors.canvasSunken,
              child: Icon(Icons.broken_image_outlined, color: AppColors.inkMute),
            ),
          ),
        // Bottom scrim with time and GPS tag.
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 44,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x000D253D), Color(0xA60D253D)],
              ),
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          bottom: AppSpacing.xs + 2,
          child: Row(children: [
            if (a.hasLocation) ...[
              const Icon(Icons.location_on_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 2),
            ],
            Expanded(
              child: Text(
                Fmt.time(a.capturedAt ?? a.createdAt),
                style: AppTypography.caption.copyWith(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Full-screen photo viewer: swipe between photos, pinch to zoom, and an
/// info panel with capture time, GPS coordinates and a map.
class PhotoViewerPage extends ConsumerStatefulWidget {
  const PhotoViewerPage({super.key, required this.attachments, this.initialIndex = 0});

  final List<Attachment> attachments;
  final int initialIndex;

  @override
  ConsumerState<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends ConsumerState<PhotoViewerPage> {
  late final _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final a = widget.attachments[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.attachments.length > 1 ? '${_index + 1} / ${widget.attachments.length}' : l10n.wsPhotos,
          style: AppTypography.subtitle.copyWith(color: Colors.white),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: widget.attachments.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final url = ref.watch(signedUrlProvider(widget.attachments[i].storagePath)).value;
              return InteractiveViewer(
                maxScale: 5,
                child: Center(
                  child: url == null
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Image.network(url, fit: BoxFit.contain, gaplessPlayback: true),
                ),
              );
            },
          ),
        ),
        _PhotoInfo(attachment: a),
      ]),
    );
  }
}

class _PhotoInfo extends StatelessWidget {
  const _PhotoInfo({required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final a = attachment;
    return Container(
      decoration: const BoxDecoration(color: AppColors.canvas, borderRadius: AppRadius.sheetTop),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const IconTile(Icons.schedule_rounded, size: 36),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(l10n.photoTakenAt(Fmt.dateTime(a.capturedAt ?? a.createdAt)), style: AppTypography.bodyStrong)),
          ]),
          const SizedBox(height: AppSpacing.md),
          if (a.hasLocation) ...[
            Row(children: [
              const IconTile(Icons.location_on_rounded, size: 36, color: AppColors.success),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text('${a.lat!.toStringAsFixed(5)}, ${a.lng!.toStringAsFixed(5)}', style: AppTypography.bodyTabular),
              ),
              TextButton.icon(
                icon: const Icon(Icons.directions_rounded, size: 18),
                label: Text(l10n.mapOpenExternal),
                onPressed: () => openInMaps(a.lat!, a.lng!),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            LocationPreview(
              height: 140,
              title: l10n.wsPhotos,
              points: [MapPoint(point: LatLng(a.lat!, a.lng!), color: AppColors.primary, icon: Icons.photo_camera_rounded)],
            ),
          ] else
            Row(children: [
              const IconTile(Icons.location_off_rounded, size: 36, color: AppColors.inkMute),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(l10n.photoNoLocation, style: AppTypography.caption)),
            ]),
          const SizedBox(height: AppSpacing.lg),
        ]),
      ),
    );
  }
}

/// Re-attaches photos taken while Android had killed the app (see
/// [AttachmentService.recoverLostPhotos]). Watched once by the app shell.
final photoRecoveryProvider =
    FutureProvider<int>((ref) => ref.read(attachmentServiceProvider).recoverLostPhotos());
