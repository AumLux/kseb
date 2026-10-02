import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/design.dart';
import '../l10n/l10n.dart';

/// Opens a modal bottom sheet in the app style: full-width, keyboard-aware,
/// scrollable, drag handle, safe-area aware. Use for every input prompt and
/// short form (Groww-style), instead of centred dialogs.
Future<T?> showAppSheet<T>(BuildContext context, {required WidgetBuilder builder}) => showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: builder,
    );

/// Layout for a sheet: title (+ optional subtitle), content, and a pinned
/// action row. Pads for the keyboard so the primary action stays reachable.
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.primaryLabel,
    this.onPrimary,
    this.primaryDestructive = false,
    this.secondaryLabel,
    this.onSecondary,
    this.busy = false,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryDestructive;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool busy;

  /// Optional icon/illustration above the title (confirmations, pickers).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (leading != null) ...[leading!, const SizedBox(height: AppSpacing.md)],
                Text(title, style: AppTypography.title),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle!, style: AppTypography.body.copyWith(color: AppColors.inkMute)),
                ],
              ]),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
              ),
            ),
            if (primaryLabel != null)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
                  child: Row(children: [
                    if (secondaryLabel != null) ...[
                      Expanded(child: AppButton.secondary(label: secondaryLabel!, onPressed: onSecondary)),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    Expanded(
                      child: primaryDestructive
                          ? AppButton.danger(label: primaryLabel!, loading: busy, onPressed: onPrimary)
                          : AppButton(label: primaryLabel!, loading: busy, onPressed: onPrimary),
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Owns [controllers] for exactly as long as the sheet/dialog subtree is
/// mounted and disposes them afterwards.
///
/// Never dispose a controller right after `await showDialog/showModalBottomSheet`:
/// the future completes when the route starts closing, while its text field
/// is still on screen for the exit animation. Disposing then throws
/// "used after being disposed" and cascades into `_dependents.isEmpty`.
class DisposeWith extends StatefulWidget {
  const DisposeWith({super.key, required this.controllers, required this.child});

  final List<ChangeNotifier> controllers;
  final Widget child;

  @override
  State<DisposeWith> createState() => _DisposeWithState();
}

class _DisposeWithState extends State<DisposeWith> {
  @override
  void dispose() {
    for (final c in widget.controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Asks for one line (or a short paragraph) of text in a bottom sheet.
/// Returns the trimmed text, or null if dismissed.
///
/// [minLength] > 0 makes the field required.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  required String label,
  required String confirmLabel,
  String? subtitle,
  String? hint,
  String? initialValue,
  int minLength = 0,
  int maxLines = 3,
  bool destructive = false,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
}) =>
    showAppSheet<String>(
      context,
      builder: (_) => _TextPrompt(
        title: title,
        subtitle: subtitle,
        label: label,
        hint: hint,
        confirmLabel: confirmLabel,
        initialValue: initialValue,
        minLength: minLength,
        maxLines: maxLines,
        destructive: destructive,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
      ),
    );

class _TextPrompt extends StatefulWidget {
  const _TextPrompt({
    required this.title,
    required this.label,
    required this.confirmLabel,
    this.subtitle,
    this.hint,
    this.initialValue,
    required this.minLength,
    required this.maxLines,
    required this.destructive,
    this.keyboardType,
    this.inputFormatters,
  });

  final String title;
  final String? subtitle;
  final String label;
  final String? hint;
  final String confirmLabel;
  final String? initialValue;
  final int minLength;
  final int maxLines;
  final bool destructive;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<_TextPrompt> createState() => _TextPromptState();
}

class _TextPromptState extends State<_TextPrompt> {
  late final _controller = TextEditingController(text: widget.initialValue);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: SheetScaffold(
        title: widget.title,
        subtitle: widget.subtitle,
        primaryLabel: widget.confirmLabel,
        primaryDestructive: widget.destructive,
        onPrimary: _submit,
        secondaryLabel: l10n.commonCancel,
        onSecondary: () => Navigator.pop(context),
        children: [
          AppTextField(
            label: widget.label,
            hint: widget.hint,
            controller: _controller,
            required: widget.minLength > 0,
            autofocus: true,
            maxLines: widget.maxLines,
            minLines: 1,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            textCapitalization: TextCapitalization.sentences,
            validator: widget.minLength > 0
                ? (v) => (v?.trim().length ?? 0) >= widget.minLength ? null : l10n.fieldRequired(widget.label)
                : null,
          ),
        ],
      ),
    );
  }
}
